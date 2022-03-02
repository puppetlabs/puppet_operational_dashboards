class puppet_operational_dashboards::profile::dashboards(
  Sensitive[String] $token = $puppet_operational_dashboards::telegraf_token,
  String $grafana_host = $facts['fqdn'],
  Integer $grafana_port = 3000,
  Sensitive[String] $grafana_password = Sensitive('admin'),
  String $grafana_version = '8.2.2',
  String $grafana_datasource = 'influxdb_puppet',
  String $grafana_install = $facts['os']['family'] ? {
    /(RedHat|Debian)/ => 'repo',
    default           => 'package',
  },
  Boolean $use_ssl = true,
  String $influxdb_host = $puppet_operational_dashboards::influxdb_host,
  Integer $influxdb_port = $puppet_operational_dashboards::influxdb_port,
  String $initial_bucket = $puppet_operational_dashboards::initial_bucket,
){
  class {'grafana':
    install_method      => $grafana_install,
    version             => $grafana_version,
    manage_package_repo => $manage_grafana_repo,
  }

  Grafana_datasource {
    require => [Class['grafana'], Service['grafana-server']],
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  grafana_datasource {$grafana_datasource:
    #FIXME: grafana ssl
    grafana_user     => 'admin',
    grafana_password => $grafana_password.unwrap,
    grafana_url      => "http://${grafana_host}:${grafana_port}",
    type             => 'influxdb',
    database         => $initial_bucket,
    url              => "${protocol}://${influxdb_host}:${influxdb_port}",
    access_mode      => 'proxy',
    is_default       => false,
    json_data        => {
      httpHeaderName1 => 'Authorization',
      httpMode        => 'GET',
      tlsSkipVerify   => true
    },
    secure_json_data => {
      httpHeaderValue1 => "Token ${token.unwrap}",
    },
  }

  ['Puppetserver', 'Puppetdb', 'Postgresql', 'Filesync'].each |$service| {
    grafana_dashboard { "${service} Performance":
      grafana_user     => 'admin',
      grafana_password => $grafana_password.unwrap,
      grafana_url      => "http://${grafana_host}:${grafana_port}",
      content          => file("puppet_operational_dashboards/${service}_performance.json"),
      require          => Grafana_datasource[$grafana_datasource],
    }
  }
}
