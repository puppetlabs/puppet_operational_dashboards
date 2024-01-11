# @summary Allows Telegraf to connect and collect metrics from postgres nodes
# @example Basic usage
#   include puppet_operational_dashboards::profile::foss_postgres_access
# @param telegraf_hosts
#   A list of FQDNs running Telegraf to allow access to
# @param telegraf_user
#   Username for the Telegraf client to use in the postgres connection string
class puppet_operational_dashboards::profile::foss_postgres_access (
  Array $telegraf_hosts = puppet_operational_dashboards::hosts_with_profile('Puppet_operational_dashboards::Telegraf::Agent'),
  String $telegraf_user = 'telegraf',
) {
  postgresql::server::role { $telegraf_user:
    ensure => present,
    db     => 'puppetdb',
  }

  postgresql::server::database_grant { "puppetdb grant connect to ${telegraf_user}":
    privilege => 'CONNECT',
    db        => 'puppetdb',
    role      => $telegraf_user,
    require   => Postgresql::Server::Role[$telegraf_user],
  }

  postgresql::server::grant_role { 'monitoring':
    group   => 'pg_monitor',
    role    => $telegraf_user,
    require => Postgresql::Server::Role[$telegraf_user],
  }

  postgresql::server::pg_hba_rule { "Allow certificate mapped connections to puppetdb as ${telegraf_user} (ipv4)":
    type        => 'hostssl',
    database    => 'puppetdb',
    user        => $telegraf_user,
    address     => '0.0.0.0/0',
    auth_method => 'cert',
    order       => 0,
    auth_option => 'map=puppetdb-telegraf-map clientcert=1',
  }

  postgresql::server::pg_hba_rule { "Allow certificate mapped connections to puppetdb as ${telegraf_user} (ipv6)":
    type        => 'hostssl',
    database    => 'puppetdb',
    user        => $telegraf_user,
    address     => '::0/0',
    auth_method => 'cert',
    order       => 0,
    auth_option => 'map=puppetdb-telegraf-map clientcert=1',
  }
  $telegraf_hosts.each |$host| {
    postgresql::server::pg_ident_rule { "Map the SSL certificate of ${host} as a puppetdb user":
      map_name          => 'puppetdb-telegraf-map',
      system_username   => $host,
      database_username => $telegraf_user,
    }
  }
}
