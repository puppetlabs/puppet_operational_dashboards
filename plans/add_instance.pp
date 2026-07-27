# @summary Onboard another PE installation into an existing operational dashboards node.
#
#   Generates a certificate for the dashboard node on the new installation's CA, distributes it to the
#   dashboard node under the file names the pe_instances parameter expects, and prints the Hiera entries
#   to add on each side.  Note that the private key passes through the Bolt controller while being copied
#   between the two installations.
#
# @param primary
#   The new installation's primary server, where the CA runs.  Must accept root SSH or an equivalent
#   privileged transport.
# @param dashboard
#   The dashboard node running Telegraf, InfluxDB, and Grafana.
# @param instance_name
#   Name for the new installation, used as the pe_instances key, the pe_instance tag value, and the
#   certificate file prefix on the dashboard node.
# @param scrape_certname
#   Certname to generate for the dashboard node's scrape certificate.  Defaults to
#   'dashboard-telegraf-<instance_name>' in lower case.
plan puppet_operational_dashboards::add_instance (
  TargetSpec $primary,
  TargetSpec $dashboard,
  String[1] $instance_name,
  Optional[String[1]] $scrape_certname = undef,
) {
  $primary_targets = get_targets($primary)
  $dashboard_targets = get_targets($dashboard)
  unless $primary_targets.size == 1 and $dashboard_targets.size == 1 {
    fail_plan('The primary and dashboard parameters must each specify exactly one target.')
  }
  $primary_target = $primary_targets[0]
  $dashboard_target = $dashboard_targets[0]

  $certname = pick($scrape_certname, "dashboard-telegraf-${instance_name.downcase()}")

  $ssl_dir = '/etc/puppetlabs/puppet/ssl'
  $sources = {
    'cert' => "${ssl_dir}/certs/${certname}.pem",
    'key'  => "${ssl_dir}/private_keys/${certname}.pem",
    'ca'   => "${ssl_dir}/certs/ca.pem",
  }

  # Generate the certificate on the new installation's CA unless it already exists, e.g. on a re-run
  run_command(
    "test -f ${sources['cert']} || /opt/puppetlabs/bin/puppetserver ca generate --certname ${certname}",
    $primary_target,
    "Generate ${certname} on the installation's CA",
  )

  $sources.each |$kind, $source| {
    $destination = "/etc/telegraf/${instance_name}_${kind}.pem"
    $download = download_file($source, "add_instance/${instance_name}/${kind}", $primary_target)
    upload_file($download.first['path'], $destination, $dashboard_target)
  }

  run_command(
    "chown telegraf:telegraf /etc/telegraf/${instance_name}_*.pem && chmod 0400 /etc/telegraf/${instance_name}_*.pem",
    $dashboard_target,
    'Set certificate file ownership and permissions',
  )

  $primary_certname = run_command('/opt/puppetlabs/bin/puppet config print certname', $primary_target).first.value['stdout'].chomp

  out::message("Certificate files for '${instance_name}' are in place on ${dashboard_target.name}.")
  # lint:ignore:strict_indent heredoc content is display formatting, not code
  out::message(@("MESSAGE"))
    Add to the dashboard node's Hiera data (adjust host lists if services run on other nodes):

      puppet_operational_dashboards::pe_instances:
        ${instance_name}:
          puppetserver_hosts: ['${primary_certname}']
          puppetdb_hosts: ['${primary_certname}']
          orchestrator_hosts: ['${primary_certname}']
          postgres_hosts: ['${primary_certname}']

    Add to the new installation's Hiera data, then run the agent on its database and infrastructure nodes:

      puppet_operational_dashboards::profile::postgres_access::additional_telegraf_hosts: ['${certname}']

    The new installation must also apply puppet_operational_dashboards::enterprise_infrastructure to its
    infrastructure nodes, and the dashboard node needs access to it on ports 8140, 8081, 8143, and 5432.
    | MESSAGE
  # lint:endignore

  return({ 'instance' => $instance_name, 'certname' => $certname, 'primary' => $primary_certname })
}
