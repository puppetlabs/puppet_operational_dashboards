# @summary Installs Grafana and several dashboards to display Puppet metrics.  Included via the base class.
# @example Basic usage
#   include puppet_operational_dashboards
#
#   class {'puppet_operational_dashboards::profile::dashboards':
#     token         => '<my_sensitive_token>',
#     influxdb_host => '<influxdb_fqdn>',
#     influxdb_port => 8086,
#     initial_bucket => '<my_bucket>',
#   }
# @param token
#   Token in Sensitive format used to query InfluxDB. The token must grant priviledges to query the associated bucket in InfluxDB
# @param grafana_host
#   FQDN of the Grafana host.  Defaults to the FQDN of the agent receiving the catalog.
# @param grafana_port
#   Port used by the Grafana service.  Defaults to 3000
# @param grafana_password
#   Grafana admin password in Sensitive format.  Defaults to 'admin'
# @param grafana_version
#   Version of the Grafana package to install.  Defaults to '8.2.2'
# @param grafana_datasource
#   Name to use for the Grafana datasource.  Defaults to 'influxdb_puppet'
# @param grafana_install
#   Method to use for installing Grafana.  Defaults to using a repository on EL and Debian/Ubuntu, and package for other platforms
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.  Defaults to true
# @param manage_grafana_repo
#   Whether to manage the Grafana repository definition.  Defaults to true.
# @param influxdb_host
#   FQDN of the InfluxDB host.  Defaults to the value of the base class,
#   which looks up the value of influxdb::host with a default of $facts['fqdn']
# @param influxdb_port
#   Port used by the InfluxDB service.  Defaults to the value of the base class,
#   which looks up the value of influxdb::port with a default of 8086
# @param influxdb_bucket
#   Name of the InfluxDB bucket to query. Defaults to the value of the base class,
#   which looks up the value of influxdb::initial_bucket with a default of 'puppet_data'
# @param telegraf_token_name
#   Name of the token to retrieve from InfluxDB if not given $token
# @param influxdb_token_file
#   Location on disk of an InfluxDB admin token.
#   This token is used in this class in a Deferred function call to retrieve a Telegraf token if $token is unset
# @param provisioning_datasource_file
#   Location on disk to store datasource definition
class puppet_operational_dashboards::profile::dashboards (
  Optional[Sensitive[String]] $token = $puppet_operational_dashboards::telegraf_token,
  String $grafana_host = $facts['networking']['fqdn'],
  Integer $grafana_port = 3000,
  #TODO: document using task to change
  Sensitive[String] $grafana_password = Sensitive('admin'),
  String $grafana_version = '8.2.2',
  String $grafana_datasource = 'influxdb_puppet',
  String $grafana_install = $facts['os']['family'] ? {
    /(RedHat|Debian)/ => 'repo',
    default           => 'package',
  },
  String $provisioning_datasource_file = '/etc/grafana/provisioning/datasources/influxdb.yaml',
  Boolean $use_ssl = true,
  Boolean $manage_grafana_repo = true,
  #TODO: put these in module data?
  String $influxdb_host = $puppet_operational_dashboards::influxdb_host,
  Integer $influxdb_port = $puppet_operational_dashboards::influxdb_port,
  String $influxdb_bucket = $puppet_operational_dashboards::initial_bucket,
  String $telegraf_token_name = $puppet_operational_dashboards::telegraf_token_name,
  String $influxdb_token_file = $puppet_operational_dashboards::influxdb_token_file,
) {
  #TODO: only for local Grafana
  class { 'grafana':
    install_method      => $grafana_install,
    version             => $grafana_version,
    manage_package_repo => $manage_grafana_repo,
  }

  $grafana_url = "http://${grafana_host}:${grafana_port}"

  # grafana-service may transition to 'running' state before it is ready to accept connections,
  # so we can't rely on a require/subscribe to create dependency relationships
  exec { 'operational_dashboards_grafana_wait':
    command     => "curl -k ${grafana_url}",
    path        => ['/bin', '/usr/bin'],
    tries       => 5,
    try_sleep   => 1,
    refreshonly => true,
    subscribe   => File[$provisioning_datasource_file],
    notify => Service['grafana-server'],
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  if $token {
    file { $provisioning_datasource_file:
      ensure  => file,
      mode    => '0600',
      owner   => 'grafana',
      content => inline_epp(file('puppet_operational_dashboards/datasource.epp'), {
          name     => $grafana_datasource,
          token    => $token,
          database => $influxdb_bucket,
          url      => $influxdb_uri,
      }),
    }
  }
  else {
    $token_vars = {
      name     => $grafana_datasource,
      token => Sensitive(Deferred('influxdb::retrieve_token', [$influxdb_uri, $telegraf_token_name, $influxdb_token_file])),
      database => $influxdb_bucket,
      url      => $influxdb_uri,
    }

    file { $provisioning_datasource_file:
      ensure  => file,
      mode    => '0600',
      owner   => 'grafana',
      content => Deferred('inline_epp',
      [file('puppet_operational_dashboards/datasource.epp'), $token_vars]),
    }
  }

  ['Puppetserver', 'Puppetdb', 'Postgresql', 'Filesync'].each |$service| {
    grafana_dashboard { "${service} Performance":
      grafana_user     => 'admin',
      grafana_password => $grafana_password.unwrap,
      grafana_url      => $grafana_url,
      content          => file("puppet_operational_dashboards/${service}_performance.json"),
      require          => Exec['operational_dashboards_grafana_wait'],
    }
  }
}
