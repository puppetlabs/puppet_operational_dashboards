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
# @param grafana_use_ssl
#   Enable use of HTTPS/SSL for Grafana. This will only configure the dashboards unless 'manage_grafana' is enabled.  Defaults to false.
# @param grafana_ssl_cert_file
#   SSL certificate file to use when 'grafana_use_ssl' and 'manage_grafana' are enabled.  Defaults to '/etc/grafana/client.pem'.
# @param grafana_ssl_key_file
#   SSL private key file to use when 'grafana_use_ssl' and 'manage_grafana' are enabled.  Defaults to '/etc/grafana/client.key'.
# @param grafana_timeout
#   How long to wait for the Grafana service to start.  Defaults to 10 seconds.
# @param grafana_password
#   Grafana admin password in Sensitive format.  Defaults to 'admin'
# @param grafana_version
#   Version of the Grafana package to install.  Defaults to '8.5.20'
# @param grafana_datasource
#   Name to use for the Grafana datasource.  Defaults to 'influxdb_puppet'
# @param grafana_install
#   Method to use for installing Grafana.  Defaults to using a repository on EL and Debian/Ubuntu, and package for other platforms
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.  Defaults to true
# @param manage_grafana
#   Whether to manage installation and configuration of Grafana.  Defaults to true
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
# @param include_pe_metrics
#   Whether to include Filesync and Orchestrator dashboards
# @param manage_system_board
#   Whether the System Performance dashboard should be created
# @param system_dashboard_version
#   Version of the system dashboard to manage. v2 is compatible with puppet_metrics_collector version 7 and up
class puppet_operational_dashboards::profile::dashboards (
  Optional[Sensitive[String]] $token = $puppet_operational_dashboards::telegraf_token,
  String $grafana_host = $facts['networking']['fqdn'],
  Integer $grafana_port = 3000,
  Boolean $grafana_use_ssl = $puppet_operational_dashboards::grafana_use_ssl,
  Stdlib::Absolutepath $grafana_ssl_cert_file = $puppet_operational_dashboards::grafana_ssl_cert_file,
  Stdlib::Absolutepath $grafana_ssl_key_file = $puppet_operational_dashboards::grafana_ssl_key_file,
  Integer $grafana_timeout = 10,
  #TODO: document using task to change
  Sensitive[String] $grafana_password = Sensitive('admin'),
  String $grafana_version = '8.5.20',
  String $grafana_datasource = 'influxdb_puppet',
  String $grafana_install = $facts['os']['family'] ? {
    /(RedHat|Debian)/ => 'repo',
    default           => 'package',
  },
  Stdlib::Absolutepath $provisioning_datasource_file = '/etc/grafana/provisioning/datasources/influxdb.yaml',
  Boolean $use_ssl = $puppet_operational_dashboards::use_ssl,
  Boolean $manage_grafana = $puppet_operational_dashboards::manage_grafana,
  Boolean $manage_grafana_repo = true,
  String $influxdb_host = $puppet_operational_dashboards::influxdb_host,
  Integer $influxdb_port = $puppet_operational_dashboards::influxdb_port,
  String $influxdb_bucket = $puppet_operational_dashboards::initial_bucket,
  String $telegraf_token_name = $puppet_operational_dashboards::telegraf_token_name,
  Stdlib::Absolutepath $influxdb_token_file = $puppet_operational_dashboards::influxdb_token_file,
  Boolean $include_pe_metrics = $puppet_operational_dashboards::include_pe_metrics,
  Boolean $manage_system_board = $puppet_operational_dashboards::manage_system_board,
  Enum['v1', 'v2', 'all'] $system_dashboard_version = 'v2',
) {
  $grafana_protocol = $grafana_use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $grafana_url = "${grafana_protocol}://${grafana_host}:${grafana_port}"

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  if $manage_grafana {
    if $grafana_use_ssl {
      $grafana_cfg = { 'server' => {
          'protocol' => 'https',
          'cert_file' => $grafana_ssl_cert_file,
          'cert_key' => $grafana_ssl_key_file,
      } }
    } else { $grafana_cfg = undef }
    class { 'grafana':
      install_method      => $grafana_install,
      version             => $grafana_version,
      manage_package_repo => $manage_grafana_repo,
      cfg                 => $grafana_cfg,
    }

    if $facts['os']['family'] == 'Debian' {
      # Workaround to override the key id for the Grafana apt source
      Apt::Source <| title == 'grafana' |> {
        key => {
          'id'     => '0E22EB88E39E12277A7760AE9E439B102CF3C0C6',
          'source' => 'https://apt.grafana.com/gpg.key',
        },
      }
    }

    file { 'grafana-conf-d':
      ensure => directory,
      path   => '/etc/systemd/system/grafana-server.service.d',
    }
    file { 'wait-for-grafana':
      ensure    => file,
      path      => '/etc/systemd/system/grafana-server.service.d/wait.conf',
      subscribe => Exec['puppet_grafana_daemon_reload'],
      content   => epp('puppet_operational_dashboards/grafana_wait.epp', { timeout => $grafana_timeout }),
    }

    exec { 'puppet_grafana_daemon_reload':
      command     => 'systemctl daemon-reload',
      path        => ['/bin', '/usr/bin'],
      refreshonly => true,
      notify      => Service['grafana-server'],
    }

    # Require the install class for any dashboards when managing Grafana
    Grafana_dashboard {
      require => Class['grafana::install'],
    }

    if $token {
      file { 'grafana_provisioning_datasource':
        ensure  => file,
        path    => $provisioning_datasource_file,
        mode    => '0600',
        owner   => 'grafana',
        content => inline_epp(file('puppet_operational_dashboards/datasource.epp'), {
            name     => $grafana_datasource,
            token    => $token,
            database => $influxdb_bucket,
            url      => $influxdb_uri,
        }),
        require => Class['grafana::install'],
        notify  => Service['grafana-server'],
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
        require => Class['grafana::install'],
        notify  => Service['grafana-server'],
      }
    }
  }

  ['Puppetserver', 'Puppetdb', 'Postgresql'].each |$service| {
    grafana_dashboard { "${service} Performance":
      grafana_user     => 'admin',
      grafana_password => $grafana_password.unwrap,
      grafana_url      => $grafana_url,
      content          => file("puppet_operational_dashboards/${service}_performance.json"),
    }
  }

  $ensure_system_performance =  $manage_system_board ? {
    true    => 'present',
    default => 'absent',
  }
  $system_dashboards = $system_dashboard_version ? {
    'all' => ['System', 'System_v2'],
    'v1'  => ['System'],
    'v2'  => ['System_v2'],
  }

  # ensure => absent should remove both versions of the system performance dashboards
  if $ensure_system_performance == 'absent' {
    ['System Performance', 'System_v2 Performance'].each |$board| {
      grafana_dashboard { $board:
        ensure           => 'absent',
        grafana_user     => 'admin',
        grafana_password => $grafana_password.unwrap,
        grafana_url      => $grafana_url,
        content          => '{}',
      }
    }
  }
  else {
    $system_dashboards.each |$board| {
      grafana_dashboard { "${board} Performance":
        ensure           => present,
        grafana_user     => 'admin',
        grafana_password => $grafana_password.unwrap,
        grafana_url      => $grafana_url,
        content          => file("puppet_operational_dashboards/${board}_performance.json"),
      }
    }
  }

  if $include_pe_metrics {
    ['Filesync', 'Orchestrator'].each |$pe_service| {
      grafana_dashboard { "${pe_service} Performance":
        grafana_user     => 'admin',
        grafana_password => $grafana_password.unwrap,
        grafana_url      => $grafana_url,
        content          => file("puppet_operational_dashboards/${pe_service}_performance.json"),
      }
    }
  }
  else {
    ['Filesync', 'Orchestrator'].each |$pe_service| {
      grafana_dashboard { "${pe_service} Performance":
        ensure           => absent,
        grafana_user     => 'admin',
        grafana_password => $grafana_password.unwrap,
        grafana_url      => $grafana_url,
      }
    }
  }
}
