# @summary Apply this class to a PE PostgreSQL node to allow access by Telegraf.
#
# @param telegraf_host
#   The FQDN of the host running Telegraf. Defaults to an empty string.
#   You can define this parameter, otherwise this class will query PuppetDB for a dashboard host.
#
# @example Apply this class to PE PostgreSQL nodes
#   class { 'puppet_operational_dashboards::profile::postgres_access':
#     telegraf_host => 'dashboard.example.com',
#   }
#
class puppet_operational_dashboards::profile::postgres_access (
  Optional[String[1]] $telegraf_host = undef
) {
  unless $facts['pe_server_version'] {
    fail('This class is PE only. Please remove this class and configure PostgreSQL access for your specific configuration.')
  }
  # Unless $telegraf_host is defined, query PuppetDB for a dashboard host.

  if $telegraf_host {
    $_telegraf_host = $telegraf_host
  } else {
  $_query = puppetdb_query('resources[certname] {
      type = "Class" and
      title = "Puppet_operational_dashboards" and
      nodes {
        deactivated is null and
        expired is null
      }
      order by certname asc
      limit 1
    }')
    unless $_query.empty {
      $_telegraf_host = $_query[0]['certname']
    }
  }

  # If $telegraf_host is not defined and the query fails to find a dashboard host, issue a warning.

  if $_telegraf_host == undef {
    notify { 'You must specify telegraf_host (or apply the puppet_operational_dashboards class to an agent) to enable access.': }
  } else {
    pe_postgresql::server::role { 'telegraf': }

    pe_postgresql::server::database_grant { 'telegraf':
      privilege => 'CONNECT',
      db        => 'pe-puppetdb',
      role      => 'telegraf',
    }

    # If the fact doesn't exist then PostgreSQL is probably version 9.4.

    if $facts['pe_postgresql_info']['installed_server_version'] {
      $postgres_version = $facts['pe_postgresql_info']['installed_server_version']
    } else {
      $postgres_version = '9.4'
    }

    $telegraf_allow_settings = {
      'user'                          => 'telegraf',
      'database'                      => 'pe-puppetdb',
      'allowed_client_certname'       => $_telegraf_host,
      'pg_ident_conf_path'            => "/opt/puppetlabs/server/data/postgresql/${postgres_version}/data/pg_ident.conf",
      'ip_mask_allow_all_users_ssl'   => '0.0.0.0/0',
      'ipv6_mask_allow_all_users_ssl' => '::/0',
    }

    if defined(puppet_enterprise::pg::cert_allowlist_entry) {
      puppet_enterprise::pg::cert_allowlist_entry { 'allow-telegraf-access':
        * => $telegraf_allow_settings,
      }
    } else {
      puppet_enterprise::pg::cert_whitelist_entry { 'allow-telegraf-access':
        * => $telegraf_allow_settings,
      }
    }
  }
}
