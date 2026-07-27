# @summary Onboard another PE installation into an existing operational dashboards node.
#
#   Generates a private key on the dashboard node, has the new installation's CA sign a certificate
#   request for it, places the certificate files under the names the pe_instances parameter expects,
#   and prints the Hiera entries to add on each side.  The private key is created where it is used
#   and never leaves the dashboard node.
#
#   Runs under the PE orchestrator ('puppet plan run') as well as standalone Bolt; only run_command,
#   apply, and out::message are used.
#
# @param primary
#   The new installation's primary server, where the CA runs.
# @param dashboard
#   The dashboard node running Telegraf, InfluxDB, and Grafana.
# @param instance_name
#   Name for the new installation, used as the pe_instances key, the pe_instance tag value, and the
#   certificate file prefix on the dashboard node.
# @param scrape_certname
#   Certname to sign for the dashboard node's scrape certificate.  Defaults to
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
  $cert_file = "/etc/telegraf/${instance_name}_cert.pem"
  $key_file = "/etc/telegraf/${instance_name}_key.pem"
  $ca_file = "/etc/telegraf/${instance_name}_ca.pem"
  $csr_path = "/tmp/${certname}.csr"

  apply_prep([$primary_target, $dashboard_target])

  $cert_present = run_command(
    "test -f ${cert_file} && echo yes || echo no",
    $dashboard_target,
    'Check whether the certificate already exists',
  ).first.value['stdout'].chomp

  if $cert_present == 'no' {
    # Generate the private key and CSR on the dashboard node; only the CSR (public) travels
    run_command(
      "test -f ${key_file} || { umask 077 && openssl req -new -newkey rsa:4096 -nodes -keyout ${key_file} -subj '/CN=${certname}' -out ${csr_path}; }", # lint:ignore:140chars
      $dashboard_target,
      'Generate private key and certificate request',
    )
    $csr = run_command("cat ${csr_path}", $dashboard_target, 'Read certificate request').first.value['stdout']

    # Submit the CSR to the new installation's CA and sign it
    $cadir = run_command(
      '/opt/puppetlabs/bin/puppet config print cadir',
      $primary_target,
      'Locate the CA directory',
    ).first.value['stdout'].chomp

    apply($primary_target) {
      file { "${cadir}/requests/${certname}.pem":
        ensure  => file,
        content => $csr,
        owner   => 'pe-puppet',
        mode    => '0640',
      }
    }
    run_command(
      "/opt/puppetlabs/bin/puppetserver ca sign --certname ${certname}",
      $primary_target,
      'Sign the certificate request',
    )
    $signed_cert = run_command(
      "cat ${cadir}/signed/${certname}.pem",
      $primary_target,
      'Read the signed certificate',
    ).first.value['stdout']

    apply($dashboard_target) {
      file { $cert_file:
        ensure  => file,
        content => $signed_cert,
        owner   => 'telegraf',
        mode    => '0400',
      }
    }
    run_command("rm -f ${csr_path}", $dashboard_target, 'Remove the certificate request')
  }
  else {
    out::message("Certificate ${cert_file} already present; skipping generation.")
  }

  # The CA certificate is public and is ensured on every run
  $ca_pem = run_command(
    'cat /etc/puppetlabs/puppet/ssl/certs/ca.pem',
    $primary_target,
    "Read the installation's CA certificate",
  ).first.value['stdout']

  apply($dashboard_target) {
    file { $ca_file:
      ensure  => file,
      content => $ca_pem,
      owner   => 'telegraf',
      mode    => '0400',
    }
    file { $key_file:
      ensure => file,
      owner  => 'telegraf',
      mode   => '0400',
    }
  }

  $primary_certname = run_command(
    '/opt/puppetlabs/bin/puppet config print certname',
    $primary_target,
    "Read the primary's certname",
  ).first.value['stdout'].chomp

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
