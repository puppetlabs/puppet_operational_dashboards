# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
# @param metrics_dir
#   Path to the 'metrics' directory from a PE support script
# @param dest_dir
#   Directory to upload $metrics_dir to
# @param cleanup_metrics
#   Whether to delete metrics after processing
# @param influxdb_org
#   Name of the InfluxDB organization to configure. Defaults to 'puppetlabs'
# @param influxdb_bucket
#   Name of the InfluxDB bucket to configure and query. Defaults to 'puppet_data'
# @param influxdb_port
#   Port used by the InfluxDB service.  Defaults to the value of influxdb::port, or 8086 if unset
# @param grafana_datasource
#   Name of the Grafana datasource.  Must match the name of the InfluxDB bucket
# @param telegraf_token
#   Name of the token to retrieve from InfluxDB. Defaults to 'puppet telegraf token'
# @param token_file
#   Location on disk of an InfluxDB admin token.
#   This file is written to by the influxdb class during installation and read by the type and providers,
#   as well Deferred functions in this module.
# @param conf_dir
#   Directory to upload Telegraf configuration files to
plan puppet_operational_dashboards::load_metrics (
  TargetSpec $targets,
  String $influxdb_org = 'puppetlabs',
  String $influxdb_bucket = 'puppet_data',
  Integer $influxdb_port = 8086,
  String $grafana_datasource = $influxdb_bucket,
  String $telegraf_token = 'puppet telegraf token',
  String $token_file = '/root/.influxdb_token',
  String $conf_dir = '/tmp/telegraf',
  #TODO
  Enum['local', 'remote'] $telegraf_process = 'remote',
  String $metrics_dir,
  String $dest_dir = '/tmp',
  #TODO
  Optional[String] $token = undef,
  String $cleanup_metrics = 'true',
) {
  $targets.apply_prep

  apply ($targets) {
    $token_vars = {
      name     => $grafana_datasource,
      token    => Sensitive(Deferred('influxdb::retrieve_token', ["http://${targets}:8086", $telegraf_token, $token_file])),
      database => $influxdb_bucket,
      url      => "http://${targets}:8086",
    }

    influxdb_org { $influxdb_org:
      ensure  => present,
      use_ssl => false,
    }

    influxdb_bucket { $influxdb_bucket:
      ensure     => present,
      use_ssl    => false,
      org        => $influxdb_org,
      require    => Influxdb_org[$influxdb_org],
      token_file => $token_file,
    }

    service { 'grafana-server':
      ensure => running,
    }

    file { "/etc/grafana/provisioning/datasources/${influxdb_bucket}.yaml":
      ensure  => file,
      mode    => '0600',
      owner   => 'grafana',
      content => Deferred('inline_epp',
      [file('puppet_operational_dashboards/datasource.epp'), $token_vars]),
      notify  => Service['grafana-server'],
    }

    $telegraf_vars = {
      bucket => $influxdb_bucket,
      org => $influxdb_org,
      port => $influxdb_port,
      host => $targets,
      token => Sensitive(Deferred('influxdb::retrieve_token', ["http://${targets}:8086", $telegraf_token, $token_file])),
    }

    file { $conf_dir:
      ensure => directory,
    }
    file { "${conf_dir}/telegraf.conf":
      ensure  => file,
      content => Deferred('inline_epp', [file('puppet_operational_dashboards/telegraf.conf'), $telegraf_vars]),
    }
    file { "${conf_dir}/telegraf.conf.d":
      ensure => directory,
    }
    ['postgres.conf', 'puppetdb.conf', 'puppetserver.conf', 'system_cpu.conf', 'system_memory.conf', 'system_procs.conf'].each |$script| {
      file { "${conf_dir}/telegraf.conf.d/${script}":
        ensure => file,
        source => "puppet:///modules/puppet_operational_dashboards/scripts/${script}",
      }
    }
  }

  upload_file($metrics_dir, $dest_dir, $targets)
  return run_script(
    'puppet_operational_dashboards/scripts/import_archives.sh',
    $targets,
    'arguments' => [$conf_dir, $dest_dir, $cleanup_metrics]
  )
}
