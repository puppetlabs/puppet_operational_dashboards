# @summary Allows Telegraf to connect and collect metrics from postgres nodes
# @example Basic usage
#   include puppet_operational_dashboards::profile::postgres_access
# @param telegraf_hosts
#   A list of FQDNs running Telegraf to allow access to
class puppet_operational_dashboards::profile::postgres_access (
  Array $telegraf_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_operational_dashboards::Telegraf::Agent'),
) {
  $ident_file = "/opt/puppetlabs/server/data/postgresql/${facts['pe_postgresql_info']['installed_server_version']}/data/pg_ident.conf"

  pe_postgresql_psql {'CREATE ROLE telegraf':
    db         => 'pe-puppetdb',
    port       => '5432',
    psql_user  => 'pe-postgres',
    psql_group => 'pe-postgres',
    unless     => "SELECT rolname FROM pg_roles WHERE rolname='telegraf'",
    psql_path  => "/opt/puppetlabs/server/bin/psql",
    require    => Class['Pe_postgresql::Server'],
  }


  pe_postgresql_psql { 'telegraf_pg_monitor_grant':
    db         => 'pe-puppetdb',
    port       => '5432',
    psql_user  => 'pe-postgres',
    psql_group => 'pe-postgres',
    command    => 'GRANT pg_monitor TO telegraf',
    unless     => "select 1 from pg_roles where pg_has_role( 'telegraf', 'pg_monitor', 'member')",
    psql_path  => "/opt/puppetlabs/server/bin/psql",
    require    => Pe_postgresql_psql['CREATE ROLE telegraf'],
  }


  $telegraf_hosts.each |$host| {
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
