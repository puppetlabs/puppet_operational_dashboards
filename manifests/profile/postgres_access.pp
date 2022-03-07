# @summary Allows Telegraf to connect and collect metrics from postgres nodes
# @example Basic usage
#   include puppet_operational_dashboards::profile::postgres_access
# @param telegraf_hosts
#   A list of FQDNs running Telegraf to allow access to
class puppet_operational_dashboards::profile::postgres_access (
  Array $telegraf_hosts = [$trusted['certname']],
) {
  $telegraf_hosts.each |$host| {
    $ident_file = "/opt/puppetlabs/server/data/postgresql/${facts['pe_postgresql_info']['installed_server_version']}/data/pg_ident.conf"
    puppet_enterprise::pg::ident_entry { "telegraf_${host}":
      pg_ident_conf_path => $ident_file,
      database           => 'pe-puppetdb',
      ident_map_key      => 'pe-puppetdb-telegraf-map',
      client_certname    => $host,
      user               => 'telegraf',
    }
  }
}
