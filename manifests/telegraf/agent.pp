# @summary Installs and configures Telegraf to query hosts in a Puppet infrastructure. Included by the base class
# @example Basic usage
#   include puppet_operational_dashboards
#
#   class {'puppet_operational_dashboards::telegraf::agent':
#     token => '<sensitive_telegraf_token>',
#   }
# @param token
#   Telegraf token in Sensitive format.
# @param influxdb_host
#   FQDN of the InfluxDB host.  Defaults to $facts['fqdn']
# @param influxdb_port
#   Port used by the InfluxDB service.  Defaults to 8086.
# @param influxdb_org
#   Name of the InfluxDB organization. Defaults to 'puppetlabs'.
# @param influxdb_bucket
#   Name of the InfluxDB bucket to query. Defaults to 'puppet_data'.
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.  Defaults to true
# @param manage_ssl
#   Whether to manage Telegraf ssl configuration.  Defaults to true.
# @param manage_repo
#   Whether to install Telegraf from a repository.  Defaults to true on the RedHat family of platforms.
# @param manage_archive
#   Whether to install Telegraf from an archive source.  Defaults to true on platforms other than RedHat.
# @param manage_user
#   Whether to manage the telegraf user when installing from archive.  Defaults to true.
# @param ssl_cert_file
#   SSL certificate to be used by the telegraf service.  Defaults to the agent certificate issued by the Puppet CA for the local machine.
# @param ssl_key_file
#   Private key used in the CSR for the certificate specified by $ssl_cert_file.
#   Defaults to the private key of the local machine for generating a CSR for the Puppet CA
# @param ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.  Defaults to the Puppet CA.
# @param version
#   Version of the Telegraf package to install. Defaults to '1.21.2'.
# @param archive_location
#   URL containing an archive source for the telegraf package.  Defaults to downloading $version from dl.influxdata.com
#   Version of the Telegraf package to install. Defaults to '1.21.2'.
# @param archive_install_dir
#   Directory to install $archive_location to.  Defaults to /opt/telegraf.
# @param collection_method
#   Determines how metrics will be collected.
#   'all' will query all Puppet services across all Puppet infrastructure hosts from the node with this class applied.
#   'local' will query all Puppet services on the node with this class applied.
#   'none' will not query any services from the node with this class applied.
# @param collection_interval
#   How frequently to collect metrics.  Defaults to '10m'.
# @param puppetserver_hosts
#   Array of Puppet server hosts to collect metrics from.  Defaults to all Puppet server hosts in a PE infrastructure.
#   FOSS users need to supply a list of FQDNs
# @param puppetdb_hosts
#   Array of PuppetDB hosts to collect metrics from.  Defaults to all PuppetDB hosts in a PE infrastructure.
#   FOSS users need to supply a list of FQDNs
# @param postgres_hosts
#   Array of Postgres hosts to collect metrics from.  Defaults to all Postgres in a PE infrastructure.
#   FOSS users need to supply a list of FQDNs.
# @param profiles
#   Array of PE profiles on the node with this class applied.  Used when collection_method is set to 'local'.
#   FOSS users can use the $local_services parameter.
# @param local_services
#   Array of FOSS services to collect from when collection_method is set to 'local'.
# @param token_name
#   Name of the token to retrieve from InfluxDB if not given $token
# @param influxdb_token_file
#   Location on disk of an InfluxDB admin token.
#   This token is used in this class in a Deferred function call to retrieve a Telegraf token if $token is unset
class puppet_operational_dashboards::telegraf::agent (
  Optional[Sensitive[String]] $token = $puppet_operational_dashboards::telegraf_token,
  String $token_name = $puppet_operational_dashboards::telegraf_token_name,
  String $influxdb_token_file = $puppet_operational_dashboards::influxdb_token_file,
  String $influxdb_host = $puppet_operational_dashboards::influxdb_host,
  Integer $influxdb_port = $puppet_operational_dashboards::influxdb_port,
  String $influxdb_bucket = $puppet_operational_dashboards::initial_bucket,
  String $influxdb_org = $puppet_operational_dashboards::initial_org,
  Boolean $use_ssl = $puppet_operational_dashboards::use_ssl,
  Boolean $manage_ssl = true,
  #TODO: move platform specific parameters to module data
  Boolean $manage_repo = $facts['os']['family'] ? {
    /(RedHat|Debian)/ => true,
    default  => false,
  },
  Boolean $manage_archive = !$manage_repo,
  Boolean $manage_user = true,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',
  # Only the latest telegraf package seems to be available for Ubuntu
  String $version = $facts['os']['name'] ? {
    'Ubuntu' => 'latest',
    default  => '1.22.2-1',
  },
  # Use the $version parameter to determine the archive link, stripping the '-1' suffix.
  String $archive_location = "https://dl.influxdata.com/telegraf/releases/telegraf-${version.split('-')[0]}_linux_amd64.tar.gz",
  String $archive_install_dir = '/opt/telegraf',
  Enum['all', 'local', 'none'] $collection_method = 'all',
  String $collection_interval = '10m',

  Array $puppetserver_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Master'),
  Array $puppetdb_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Puppetdb'),
  Array $postgres_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Database'),

  Array[String] $profiles = puppet_operational_dashboards::pe_profiles_on_host(),
  Array[String] $local_services = [],
) {
  unless [$puppetserver_hosts, $puppetdb_hosts, $postgres_hosts, $profiles, $local_services].any |$service| { $service } {
    fail('No services detected on node.')
  }

  exec { 'puppet_telegraf_daemon_reload':
    command     => 'systemctl daemon-reload',
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  $influxdb_v2 = $use_ssl ? {
    true  => {
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
    false => {
      'influxdb_v2' => [
        {
          'bucket'               => $influxdb_bucket,
          'organization'         => $influxdb_org,
          'token'                => '$INFLUX_TOKEN',
          'urls'                 => [$influxdb_uri],
        }
      ],
    },
  }

  Telegraf::Input {
    notify => Service['telegraf'],
  }
  Telegraf::Output {
    notify => Service['telegraf'],
  }

  if $facts['os']['name'] == 'Ubuntu' and $version != 'latest' {
    notify { 'telegraf_ubuntu_warn':
      message  => "Using 'latest' for Telegraf package on Ubuntu",
      loglevel => 'warning',
    }
  }

  $version_ensure = $facts['os']['name'] ? {
    'Ubuntu' => 'latest',
    default  => $version,
  }

  class { 'telegraf':
    ensure              => $version_ensure,
    manage_repo         => $manage_repo,
    manage_archive      => $manage_archive,
    manage_user         => $manage_user,
    archive_location    => $archive_location,
    archive_install_dir => $archive_install_dir,
    interval            => $collection_interval,
    hostname            => '',
    manage_service      => false,
    outputs             => $influxdb_v2,
    notify              => Service['telegraf'],
  }

  if $use_ssl and $manage_ssl {
    file { '/etc/telegraf/cert.pem':
      ensure  => file,
      source  => "file:///${ssl_cert_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf::install'],
      notify  => Service['telegraf'],
    }
    file { '/etc/telegraf/key.pem':
      ensure  => file,
      source  => "file:///${ssl_key_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf::install'],
      notify  => Service['telegraf'],
    }
    file { '/etc/telegraf/ca.pem':
      ensure  => file,
      source  => "file:///${ssl_ca_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf::install'],
      notify  => Service['telegraf'],
    }
  }

  file { '/etc/systemd/system/telegraf.service.d':
    ensure  => directory,
    owner   => 'telegraf',
    group   => 'telegraf',
    mode    => '0700',
    require => Class['telegraf::install'],
  }

  if $token {
    file { '/etc/systemd/system/telegraf.service.d/override.conf':
      ensure  => file,
      content => inline_epp(file('influxdb/telegraf_environment_file.epp'), { token => $token }),
      notify  => [
        Exec['puppet_telegraf_daemon_reload'],
        Service['telegraf']
      ],
    }
  }
  else {
    $token_vars = {
      token => Sensitive(Deferred('influxdb::retrieve_token', [$influxdb_uri, $token_name, $influxdb_token_file])),
    }
    file { '/etc/systemd/system/telegraf.service.d/override.conf':
      ensure  => file,
      content => Deferred('inline_epp', [file('influxdb/telegraf_environment_file.epp'), $token_vars]),
      notify  => [
        Exec['puppet_telegraf_daemon_reload'],
        Service['telegraf'],
      ],
    }
  }

  service { 'telegraf':
    ensure  => running,
    require => [
      Class['telegraf::install'],
      Exec['puppet_telegraf_daemon_reload'],
    ],
  }

  if $collection_method == 'all' {
    unless $puppetdb_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { ['puppetdb', 'puppetdb_jvm']:
        hosts    => $puppetdb_hosts,
        protocol => $protocol,
        require  => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $puppetserver_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts    => $puppetserver_hosts,
        protocol => $protocol,
        require  => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $postgres_hosts.empty() {
      $postgres_hosts.each |$pg_host| {
        $inputs = epp(
          'puppet_operational_dashboards/postgres.epp',
          { certname     => $pg_host }
        ).influxdb::from_toml()

        telegraf::input { "postgres_${pg_host}":
          plugin_type => 'postgresql_extensible',
          options     => [$inputs],
        }
      }
    }
  }

  elsif $collection_method == 'local' {
    if 'Puppet_enterprise::Profile::Puppetdb' in $profiles or 'puppetdb' in $local_services {
      puppet_operational_dashboards::telegraf::config { ['puppetdb', 'puppetdb_jvm']:
        hosts    => [$trusted['certname']],
        protocol => $protocol,
        require  => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Master' in $profiles or 'puppetserver' in $local_services {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts    => [$trusted['certname']],
        protocol => $protocol,
        require  => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Database' in $profiles or 'postgres' in $local_services {
      $inputs = epp(
        'puppet_operational_dashboards/postgres.epp',
        { certname     => $trusted['certname'] }
      ).influxdb::from_toml()

      telegraf::input { "postgres_${trusted['certname']}":
        plugin_type => 'postgresql_extensible',
        options     => [$inputs],
      }
    }
  }
}
