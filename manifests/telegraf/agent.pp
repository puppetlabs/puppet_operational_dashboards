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
# @param ssl_cert_file
#   SSL certificate to be used by the telegraf service.  Defaults to the agent certificate issued by the Puppet CA for the local machine.
# @param ssl_key_file
#   Private key used in the CSR for the certificate specified by $ssl_cert_file.
#   Defaults to the private key of the local machine for generating a CSR for the Puppet CA
# @param ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.  Defaults to the Puppet CA.
# @param version
#   Version of the Telegraf package to install. Defaults to '1.21.2'.
# @param collection_method
#   Determines how metrics will be collected.
#   'all' will query all Puppet services across all Puppet infrastructure hosts from the node with this class applied.
#   'local' will query all Puppet services on the node with this class applied.
#   TODO
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
class puppet_operational_dashboards::telegraf::agent (
  Sensitive[String] $token,

  #TODO: standardize whether these are lookups or not
  String $influxdb_host = $facts['networking']['fqdn'],
  Integer $influxdb_port = 8086,
  String $influxdb_org = 'puppetlabs',
  String $influxdb_bucket = 'puppet_data',

  Boolean $use_ssl = true,
  Boolean $manage_ssl = true,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',

  String $version = '1.21.2',
  Enum['all', 'local', 'none'] $collection_method = 'all',
  String $collection_interval = '10m',

  Array $puppetserver_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Master'),
  Array $puppetdb_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Puppetdb'),
  Array $postgres_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Database'),

  # TODO: test this
  Array[String] $profiles = puppet_operational_dashboards::pe_profiles_on_host(),
  Array[String] $local_services = [],
) {
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
    file { '/etc/telegraf/cert.pem':
      ensure  => file,
      source  => "file:///${ssl_cert_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
    file { '/etc/telegraf/key.pem':
      ensure  => file,
      source  => "file:///${ssl_key_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
    file { '/etc/telegraf/ca.pem':
      ensure  => file,
      source  => "file:///${ssl_ca_file}",
      mode    => '0400',
      owner   => 'telegraf',
      require => Class['telegraf'],
    }
  }

  file { '/etc/systemd/system/telegraf.service.d':
    ensure => directory,
    owner  => 'telegraf',
    group  => 'telegraf',
    mode   => '0700',
  }
  file { '/etc/systemd/system/telegraf.service.d/override.conf':
    ensure  => file,
    content => epp('influxdb/telegraf_environment_file.epp', { token => $token }),
    notify  => Service['telegraf'],
  }

  if $collection_method == 'all' {
    unless $puppetdb_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { ['puppetdb', 'puppetdb_jvm']:
        hosts   => $puppetdb_hosts,
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $puppetserver_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts   => $puppetserver_hosts,
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
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
        hosts   => [$trusted['certname']],
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Master' in $profiles or 'puppetserver' in $local_services {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts   => [$trusted['certname']],
        require => File['/etc/systemd/system/telegraf.service.d/override.conf'],
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
