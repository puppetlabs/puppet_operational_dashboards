class puppet_operational_dashboards::telegraf::agent(
  Sensitive[String] $token,

  String $influxdb_host = $facts['fqdn'],
  Integer $influxdb_port = 8086,
  String $influxdb_org = 'puppetlabs',
  String $influxdb_bucket = 'puppet_data',

  Boolean $use_ssl = true,
  Boolean $manage_ssl = true,
  String  $ssl_cert_file = "${facts['puppet_ssldir']}/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="${facts['puppet_ssldir']}/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ="${facts['puppet_ssldir']}/certs/ca.pem",

  String $version = '1.21.2',
  Enum['all', 'local', 'none'] $collection_method = 'all',
  String  $config_file = '/etc/telegraf/telegraf.conf',
  String  $config_dir = '/etc/telegraf/telegraf.d',
  String $collection_interval = '10m',

  Array $puppetserver_hosts = puppet_operational_dashboards::hosts_with_pe_profile('Master'),
  Array $puppetdb_hosts     = puppet_operational_dashboards::hosts_with_pe_profile('Puppetdb'),
  Array $postgres_hosts     = puppet_operational_dashboards::hosts_with_pe_profile('Database'),

  # TODO: test this
  Array[String] $profiles = puppet_operational_dashboards::pe_profiles_on_host(),
  Array[String] $local_services = [],
){
  unless [$puppetserver_hosts, $puppetdb_hosts, $postgres_hosts, $profiles, $local_services].any |$service| { $service } {
    fail('No services detected on node.')
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  Telegraf::Input {
    notify => Service['telegraf'],
  }
  Telegraf::Output {
    notify => Service['telegraf'],
  }

  class { 'telegraf':
    ensure           => $version,
    archive_location => 'https://dl.influxdata.com/telegraf/releases/telegraf-1.21.2_linux_amd64.tar.gz',
    interval         => $collection_interval,
    hostname         => '',
    manage_service   => true,
    outputs          => {
      'influxdb_v2' => [
        {
          'tls_ca'               => '/etc/telegraf/ca.pem',
          'tls_cert'             => '/etc/telegraf/cert.pem',
          'insecure_skip_verify' => true,
          'bucket'               => $influxdb_bucket,
          'organization'         => $influxdb_org,
          'token'                => '$INFLUX_TOKEN',
          'urls'                 => [$influxdb_uri],
        }
      ],
    },
  }

  if $use_ssl and $manage_ssl {
    file {'/etc/telegraf/cert.pem':
      ensure  => present,
      source  => "file:///${ssl_cert_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
    file {'/etc/telegraf/key.pem':
      ensure  => present,
      source  => "file:///${ssl_key_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
    file {'/etc/telegraf/ca.pem':
      ensure  => present,
      source  => "file:///${ssl_ca_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
  }

  file {'/etc/systemd/system/telegraf.service.d':
    ensure => directory,
    owner  => 'telegraf',
    group  => 'telegraf',
    mode   => '0700',
  }
  file {'/etc/systemd/system/telegraf.service.d/override.conf':
    ensure  => file,
    content => epp('influxdb/telegraf_environment_file.epp', { token => $token }),
    notify  => Service['telegraf'],
  }

  if $collection_method == 'all' {
    unless $puppetdb_hosts.empty() {
      puppet_operational_dashboards::telegraf::config {['puppetdb', 'puppetdb_jvm']:
        hosts   => $puppetdb_hosts,
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $puppetserver_hosts.empty() {
      puppet_operational_dashboards::telegraf::config {'puppetserver':
        hosts   => $puppetserver_hosts,
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $postgres_hosts.empty() {
      if $facts['pe_postgresql_info'] {
        include puppet_operational_dashboards::profile::postgres_access
      }

      $postgres_hosts.each |$pg_host| {
        $inputs = epp(
          'puppet_operational_dashboards/postgres.epp',
          { certname     => $pg_host }
        ).influxdb::from_toml()

        telegraf::input {"postgres_${pg_host}":
          plugin_type => 'postgresql_extensible',
          options     => [$inputs],
        }
      }
    }
  }

  elsif $collection_method == 'local' {
    if 'Puppet_enterprise::Profile::Puppetdb' in $profiles or 'puppetdb' in $local_services {
      puppet_operational_dashboards::telegraf::config {['puppetdb', 'puppetdb_jvm']:
        hosts   => [$trusted['certname']],
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Master' in $profiles or 'puppetserver' in $local_services {
      puppet_operational_dashboards::telegraf::config {'puppetserver':
        hosts   => [$trusted['certname']],
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Database' in $profiles or 'postgres' in $local_services {
      $inputs = epp(
        'puppet_operational_dashboards/postgres.epp',
        { certname     => $trusted['certname'] }
      ).influxdb::from_toml()

      telegraf::input {"postgres_${trusted['certname']}":
        plugin_type => 'postgresql_extensible',
        options     => [$inputs],
      }
    }
  }
}
