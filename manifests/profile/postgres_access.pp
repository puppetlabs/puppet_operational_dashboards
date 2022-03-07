class puppet_operational_dashboards::profile::postgres_access (
  Array $postgres_hosts = puppet_operational_dashboards::hosts_with_pe_profile('Database'),
) {
  $postgres_hosts.each |$host| {
    puppet_enterprise::pg::ident_entry { "telegraf_${host}":
      pg_ident_conf_path => $ident_file,
      database           => 'pe-puppetdb',
      ident_map_key      => 'pe-puppetdb-telegraf-map',
      client_certname    => $host,
      user               => 'telegraf',
    }
  }
}
