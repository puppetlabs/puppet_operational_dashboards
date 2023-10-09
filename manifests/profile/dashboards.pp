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
#   FQDN of the Grafana host.
# @param grafana_port
#   Port used by the Grafana service.
# @param grafana_use_ssl
#   Enable use of HTTPS/SSL for Grafana.
# @param manage_grafana_ssl
#   Whether to manage the SSL certificate files when using the grafana_use_ssl parameter.
# @param grafana_cert_file
#   SSL certificate file to use when 'grafana_use_ssl' and 'manage_grafana' are enabled.
# @param grafana_key_file
#   SSL private key file to use when 'grafana_use_ssl' and 'manage_grafana' are enabled.
# @param grafana_cert_file_source
#   SSL certificate file to use as the source for the grafana_cert_file parameter.
# @param grafana_key_file_source
#   SSL certificate file to use as the source for the grafana_key_file parameter.
# @param grafana_timeout
#   How long to wait for the Grafana service to start.
# @param grafana_password
#   Grafana admin password in Sensitive format.
# @param grafana_version
#   Version of the Grafana package to install.
# @param grafana_datasource
#   Name to use for the Grafana datasource.
# @param grafana_install
#   Method to use for installing Grafana.
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.
# @param use_system_store
#   Whether to use the system CA bundle.
# @param manage_grafana
#   Whether to manage installation and configuration of Grafana.
# @param manage_grafana_repo
#   Whether to manage the Grafana repository definition.
# @param influxdb_host
#   FQDN of the InfluxDB host.
# @param influxdb_port
#   Port used by the InfluxDB service.
# @param influxdb_bucket
#   Name of the InfluxDB bucket to query.
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
  Boolean $grafana_use_ssl = false,
  Boolean $manage_grafana_ssl = true,
  Stdlib::Absolutepath $grafana_cert_file_source = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  Stdlib::Absolutepath $grafana_key_file_source ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  Stdlib::Absolutepath $grafana_cert_file = '/etc/grafana/client.pem',
  Stdlib::Absolutepath $grafana_key_file = '/etc/grafana/client.key',
  Integer $grafana_timeout = 10,
  #TODO: document using task to change
  Sensitive[String] $grafana_password = Sensitive('admin'),
  String $grafana_version = '8.5.27',
  String $grafana_datasource = 'influxdb_puppet',
  String $grafana_install = $facts['os']['family'] ? {
    /(RedHat|Debian)/ => 'repo',
    default           => 'package',
  },
  Stdlib::Absolutepath $provisioning_datasource_file = '/etc/grafana/provisioning/datasources/influxdb.yaml',
  Boolean $use_ssl = $puppet_operational_dashboards::use_ssl,
  Boolean $use_system_store = $puppet_operational_dashboards::use_system_store,
  Boolean $manage_grafana = true,
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
      $grafana_cfg = {
        'server' => {
          'protocol' => 'https',
          'cert_file' => $grafana_cert_file,
          'cert_key' => $grafana_key_file,
        },
      }
      class { 'grafana':
        install_method      => $grafana_install,
        version             => $grafana_version,
        manage_package_repo => $manage_grafana_repo,
        cfg                 => $grafana_cfg,
      }
      if $manage_grafana_ssl {
        file { $grafana_key_file:
          ensure => file,
          source => "file:///${grafana_key_file_source}",
          notify => Service['grafana-server'],
        }
        file { $grafana_cert_file:
          ensure => file,
          source => "file:///${grafana_cert_file_source}",
          notify => Service['grafana-server'],
        }
      }
    }
    else {
      class { 'grafana':
        install_method      => $grafana_install,
        version             => $grafana_version,
        manage_package_repo => $manage_grafana_repo,
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
      content   => epp('puppet_operational_dashboards/grafana_wait.epp', { timeout => $grafana_timeout, port => $grafana_port }),
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
        token => Sensitive(Deferred('influxdb::retrieve_token',
          [$influxdb_uri, $telegraf_token_name, $influxdb_token_file, $use_system_store])
        ),
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
