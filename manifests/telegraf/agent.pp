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
#   FQDN of the InfluxDB host.
# @param influxdb_port
#   Port used by the InfluxDB service.
# @param influxdb_org
#   Name of the InfluxDB organization.
# @param influxdb_bucket
#   Name of the InfluxDB bucket to query.
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.
# @param use_system_store
#   Whether to use the system CA bundle.
# @param manage_ssl
#   Whether to manage Telegraf ssl configuration.
# @param manage_repo
#   Whether to install Telegraf from a repository.
# @param manage_archive
#   Whether to install Telegraf from an archive source.
# @param manage_user
#   Whether to manage the telegraf user when installing from archive.
# @param ssl_cert_file
#   SSL certificate to be used by the telegraf service.
# @param ssl_key_file
#   Private key used in the CSR for the certificate specified by $ssl_cert_file.
# @param ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.
# @param puppet_ssl_cert_file
#   SSL certificate to be used by the telegraf inputs.
# @param puppet_ssl_key_file
#   Private key used in the CSR for the certificate specified by $puppet_ssl_cert_file.
# @param puppet_ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $puppet_ssl_cert_file.
# @param insecure_skip_verify
#   Skip verification of SSL certificate.
# @param version
#   Version of the Telegraf package to install.
# @param archive_location
#   URL containing an archive source for the telegraf package.  Defaults to downloading $version from dl.influxdata.com
# @param archive_install_dir
#   Directory to install $archive_location to.
# @param collection_method
#   Determines how metrics will be collected.
#   'all' will query all Puppet services across all Puppet infrastructure hosts from the node with this class applied.
#   'local' will query all Puppet services on the node with this class applied.
#   'none' will not query any services from the node with this class applied.
# @param collection_interval
#   How frequently to collect metrics.
# @param puppetserver_hosts
#   Array of Puppet server hosts to collect metrics from. FOSS users need to supply a list of FQDNs.
# @param puppetdb_hosts
#   Array of PuppetDB hosts to collect metrics from. FOSS users need to supply a list of FQDNs.
# @param postgres_hosts
#   Array of Postgres hosts to collect metrics from. FOSS users need to supply a list of FQDNs.
# @param orchestrator_hosts
#   Array of Orchestrator hosts to collect metrics from. FOSS users need to supply a list of FQDNs.
# @param profiles
#   Array of PE profiles on the node with this class applied. Used when collection_method is set to 'local'.
#   FOSS users can use the $local_services parameter.
# @param local_services
#   Array of FOSS services to collect from when collection_method is set to 'local'.
# @param token_name
#   Name of the token to retrieve from InfluxDB if not given $token
# @param influxdb_token_file
#   Location on disk of an InfluxDB admin token.
#   This token is used in this class in a Deferred function call to retrieve a Telegraf token if $token is unset
# @param http_timeout_seconds
#   Timeout for HTTP Telegraf inputs. Might be usefull in huge environments with slower API responses
# @param include_pe_metrics
#   Whether to include Filesync and Orchestrator dashboards
# @param telegraf_user
#   Username for the Telegraf client to use in the postgres connection string
# @param telegraf_postgres_password
#   Optional Sensitive password for the Telegraf client to use in the postgres connection string
# @param postgres_port
#   Port for the Telegraf client to use in the postgres connection string
# @param postgres_options
#   Hash of options for the Telegraf client to use as connection parameters in the postgres connection string
class puppet_operational_dashboards::telegraf::agent (
  String $version,
  Boolean $manage_repo,
  Optional[Sensitive[String]] $token = $puppet_operational_dashboards::telegraf_token,
  String $token_name = $puppet_operational_dashboards::telegraf_token_name,
  String $influxdb_token_file = $puppet_operational_dashboards::influxdb_token_file,
  String $influxdb_host = $puppet_operational_dashboards::influxdb_host,
  Integer $influxdb_port = $puppet_operational_dashboards::influxdb_port,
  String $influxdb_bucket = $puppet_operational_dashboards::initial_bucket,
  String $influxdb_org = $puppet_operational_dashboards::initial_org,
  Boolean $use_ssl = $puppet_operational_dashboards::use_ssl,
  Boolean $use_system_store = $puppet_operational_dashboards::use_system_store,
  Boolean $manage_ssl = true,
  Boolean $insecure_skip_verify = true,
  Boolean $manage_archive = !$manage_repo,
  Boolean $manage_user = true,
  Stdlib::Absolutepath  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  Stdlib::Absolutepath  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  Stdlib::Absolutepath  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',
  Stdlib::Absolutepath  $puppet_ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  Stdlib::Absolutepath  $puppet_ssl_key_file = "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  Stdlib::Absolutepath  $puppet_ssl_ca_file = '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
  # Use the $version parameter to determine the archive link, stripping the '-1' suffix.
  String $archive_location = "https://dl.influxdata.com/telegraf/releases/telegraf-${version.split('-')[0]}_linux_amd64.tar.gz",
  String $archive_install_dir = '/opt/telegraf',
  Enum['all', 'local', 'none'] $collection_method = 'all',
  String $collection_interval = '10m',

  Array $puppetserver_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Master'),
  Array $orchestrator_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Orchestrator'),
  Array $puppetdb_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Puppetdb'),
  Array $postgres_hosts     = puppet_operational_dashboards::hosts_with_profile('Puppet_enterprise::Profile::Database'),

  Array[String] $profiles = puppet_operational_dashboards::pe_profiles_on_host(),
  Array[String] $local_services = [],
  Integer[1] $http_timeout_seconds = 5,
  # Check for PE by looking at the compiling server's module_groups setting
  Boolean $include_pe_metrics = $puppet_operational_dashboards::include_pe_metrics,
  String $telegraf_user = 'telegraf',
  Optional[Sensitive[String]] $telegraf_postgres_password = undef,

  Integer $postgres_port = 5432,
  Hash $postgres_options = {
    'sslmode'     => 'verify-full',
    'sslkey'      => '/etc/telegraf/puppet_key.pem',
    'sslcert'     => '/etc/telegraf/puppet_cert.pem',
    'sslrootcert' => '/etc/telegraf/puppet_ca.pem',
  }
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
          'insecure_skip_verify' => $insecure_skip_verify,
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

  $database = if $include_pe_metrics {
    'pe-puppetdb'
  }
  else {
    'puppetdb'
  }

  Telegraf::Input {
    notify => Service['telegraf'],
  }
  Telegraf::Output {
    notify => Service['telegraf'],
  }

  class { 'telegraf':
    ensure              => $version,
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
    file { '/etc/telegraf/puppet_cert.pem':
      ensure  => file,
      source  => "file:///${puppet_ssl_cert_file}",
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
    file { '/etc/telegraf/puppet_key.pem':
      ensure  => file,
      source  => "file:///${puppet_ssl_key_file}",
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
    file { '/etc/telegraf/puppet_ca.pem':
      ensure  => file,
      source  => "file:///${puppet_ssl_ca_file}",
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
      token => Sensitive(Deferred('influxdb::retrieve_token', [$influxdb_uri, $token_name, $influxdb_token_file, $use_system_store])),
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
        hosts                => $puppetdb_hosts.sort,
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $puppetserver_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts                => $puppetserver_hosts.sort,
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $orchestrator_hosts.empty() {
      puppet_operational_dashboards::telegraf::config { 'orchestrator':
        hosts                => $orchestrator_hosts.sort,
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    unless $postgres_hosts.empty() {
      $postgres_hosts.sort.each |$pg_host| {
        $options = $postgres_options.map |$k, $v| { "${k}=${v}" }.join('&')
        $inputs = epp(
          'puppet_operational_dashboards/postgres.epp',
          {
            certname          => $pg_host,
            telegraf_user     => $telegraf_user,
            password          => $telegraf_postgres_password,
            database          => $database,
            port              => $postgres_port,
            connection_params => $options,
          }
        ).stdlib::from_toml()

        telegraf::input { "postgres_${pg_host}":
          plugin_type => 'postgresql_extensible',
          options     => [$inputs],
        }
      }
    }

    # The port to use for this mbean is 8143 for Orchestrator and 8140 for Puppet server
    if $include_pe_metrics {
      $pcp_hosts = $puppetserver_hosts.map |$host| {
        if $host in $orchestrator_hosts {
          "${host}:8143"
        }
        else {
          "${host}:8140"
        }
      }

      unless $pcp_hosts.empty() {
        puppet_operational_dashboards::telegraf::config { 'pcp':
          hosts                => $pcp_hosts.sort,
          protocol             => $protocol,
          http_timeout_seconds => $http_timeout_seconds,
          require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
        }
      }
    }
  }

  elsif $collection_method == 'local' {
    $pcp_port = ('Puppet_enterprise::Profile::Orchestrator' in $profiles or 'orchestrator' in $local_services) ? {
      true  => 8143,
      false => 8140
    }
    if 'Puppet_enterprise::Profile::Puppetdb' in $profiles or 'puppetdb' in $local_services {
      puppet_operational_dashboards::telegraf::config { ['puppetdb', 'puppetdb_jvm']:
        hosts                => [$trusted['certname']],
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Master' in $profiles or 'puppetserver' in $local_services {
      puppet_operational_dashboards::telegraf::config { 'puppetserver':
        hosts                => [$trusted['certname']],
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
      if $include_pe_metrics {
        puppet_operational_dashboards::telegraf::config { 'pcp':
          hosts                => ["${trusted['certname']}:${pcp_port}"],
          protocol             => $protocol,
          http_timeout_seconds => $http_timeout_seconds,
          require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
        }
      }
    }

    if 'Puppet_enterprise::Profile::Orchestrator' in $profiles or 'orchestrator' in $local_services {
      puppet_operational_dashboards::telegraf::config { 'orchestrator':
        hosts                => $orchestrator_hosts.sort,
        protocol             => $protocol,
        http_timeout_seconds => $http_timeout_seconds,
        require              => File['/etc/systemd/system/telegraf.service.d/override.conf'],
      }
    }

    if 'Puppet_enterprise::Profile::Database' in $profiles or 'postgres' in $local_services {
      $options = $postgres_options.map |$k, $v| { "${k}=${v}" }.join('&')
      $inputs = epp(
        'puppet_operational_dashboards/postgres.epp',
        {
          certname                   => $trusted['certname'],
          telegraf_user              => $telegraf_user,
          password                   => $telegraf_postgres_password,
          database                   => $database,
          port                       => $postgres_port,
          connection_params          => $options,
        }
      ).stdlib::from_toml()

      telegraf::input { "postgres_${trusted['certname']}":
        plugin_type => 'postgresql_extensible',
        options     => [$inputs],
      }
    }
  }
}
