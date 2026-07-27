# @summary Allows Telegraf to connect and collect metrics from postgres nodes
# @example Basic usage
#   include puppet_operational_dashboards::profile::postgres_access
# @param telegraf_hosts
#   A list of FQDNs running Telegraf to allow access to.  Defaults to hosts in this installation's
#   PuppetDB with the telegraf agent class.  Setting this replaces the discovered list.
# @param additional_telegraf_hosts
#   A list of certnames to allow access to in addition to the discovered (or given) telegraf_hosts.
#   Use this for scrapers outside this installation, such as a dashboard node collecting several PE
#   installations, whose certnames cannot be discovered from this installation's PuppetDB.
class puppet_operational_dashboards::profile::postgres_access (
  Array $telegraf_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_operational_dashboards::Telegraf::Agent'),
  Array[String[1]] $additional_telegraf_hosts = [],
) {
  $ident_file = "/opt/puppetlabs/server/data/postgresql/${facts['pe_postgresql_info']['installed_server_version']}/data/pg_ident.conf"

  pe_postgresql_psql { 'CREATE ROLE telegraf LOGIN':
    db         => 'pe-puppetdb',
    port       => '5432',
    psql_user  => 'pe-postgres',
    psql_group => 'pe-postgres',
    unless     => "SELECT rolname FROM pg_roles WHERE rolname='telegraf'",
    psql_path  => '/opt/puppetlabs/server/bin/psql',
    require    => Class['Pe_postgresql::Server'],
  }

  pe_postgresql::server::database_grant { 'operational_dashboards_telegraf':
    privilege => 'CONNECT',
    db        => 'pe-puppetdb',
    role      => 'telegraf',
    require   => Pe_postgresql_psql['CREATE ROLE telegraf LOGIN'],
  }

  pe_postgresql_psql { 'telegraf_pg_monitor_grant':
    db         => 'pe-puppetdb',
    port       => '5432',
    psql_user  => 'pe-postgres',
    psql_group => 'pe-postgres',
    command    => 'GRANT pg_monitor TO telegraf',
    unless     => "select 1 from pg_roles where pg_has_role( 'telegraf', 'pg_monitor', 'member')",
    psql_path  => '/opt/puppetlabs/server/bin/psql',
    require    => Pe_postgresql_psql['CREATE ROLE telegraf LOGIN'],
  }

  ($telegraf_hosts + $additional_telegraf_hosts).unique.each |$host| {
    puppet_enterprise::pg::cert_allowlist_entry { "telegraf_${host}":
      user                          => 'telegraf',
      database                      => 'pe-puppetdb',
      allowed_client_certname       => $host,
      pg_ident_conf_path            => $ident_file,
      ip_mask_allow_all_users_ssl   => '0.0.0.0/0',
      ipv6_mask_allow_all_users_ssl => '::/0',
    }
  }
}
