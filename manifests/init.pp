# @summary Installs Telegraf, InfluxDB, and Grafana to collect and display Puppet metrics
# @example Basic usage
#   include puppet_operational_dashboards
#
#   class {'puppet_operational_dashboards':
#     manage_influxdb => false,
#     influxdb_host   => '<influxdb_fqdn>',
#   }
# @param manage_influxdb
#   Whether to manage installation and configuration of InfluxDB.
# @param influxdb_host
#   FQDN of the InfluxDB host.
# @param influxdb_port
#   Port used by the InfluxDB service.
# @param initial_org
#   Name of the InfluxDB organization to configure.
# @param initial_bucket
#   Name of the InfluxDB bucket to configure and query.
# @param influxdb_bucket_retention_rules
#   Value for the initial InfluxDB bucket retention rules, Values are the same as in the influx_bucket type of the InfluxDB module.
# @param influxdb_token
#   InfluxDB admin token in Sensitive format.
#   See the puppetlabs/influxdb documentation for more information about this token.
# @param telegraf_token_name
#   Name of the token to retrieve from InfluxDB if not given $telegraf_token.
# @param manage_telegraf
#   Whether to manage installation and configuration of Telegraf.
# @param manage_telegraf_token
#   Whether to create and manage a Telegraf token with permissions to query buckets in the default organization.
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.
# @param use_system_store
#   Whether to use the system CA bundle.
# @param influxdb_token_file
#   Location on disk of an InfluxDB admin token.
#   This file is written to by the influxdb class during installation and read by the type and providers,
#   as well Deferred functions in this module.
# @param telegraf_token
#   Telegraf token in Sensitive format.
# @param include_pe_metrics
#   Whether to include Filesync and Orchestrator dashboards
# @param manage_system_board
#   Whether the System Performance dashboard should be added to grafana
class puppet_operational_dashboards (
  Boolean $manage_influxdb = true,
  String $influxdb_host = lookup(influxdb::host, undef, undef, $facts['networking']['fqdn']),
  Integer $influxdb_port = lookup(influxdb::port, undef, undef, 8086),
  String $initial_org = lookup(influxdb::initial_org, undef, undef, 'puppetlabs'),
  String $initial_bucket = lookup(influxdb::initial_bucket, undef, undef, 'puppet_data'),
  Array $influxdb_bucket_retention_rules = [{ 'type' => 'expire', 'everySeconds' => 7776000, 'shardGroupDurationSeconds' => 604800 }],

  Optional[Sensitive[String]] $influxdb_token = lookup(influxdb::token, undef, undef, undef),
  Optional[Sensitive[String]] $telegraf_token = undef,
  String $telegraf_token_name = 'puppet telegraf token',
  String $influxdb_token_file = lookup(influxdb::token_file, undef, undef, $facts['identity']['user'] ? {
      'root'  => '/root/.influxdb_token',
      default => "/home/${facts['identity']['user']}/.influxdb_token"
  }),
  Boolean $manage_telegraf = true,
  Boolean $manage_telegraf_token = true,
  Boolean $use_ssl = true,
  Boolean $use_system_store = lookup(influxdb::use_system_store, undef, undef, false),
  # Check for PE by looking at the compiling server's module_groups setting
  Boolean $include_pe_metrics = $settings::module_groups =~ 'pe_only',
  Boolean $manage_system_board = true,
) {
  unless $facts['os']['family'] in ['RedHat', 'Debian', 'Suse'] {
    fail("Installation on ${facts['os']['family']} is not supported")
  }

  if $manage_influxdb {
    class { 'influxdb':
      host             => $influxdb_host,
      port             => $influxdb_port,
      use_ssl          => $use_ssl,
      use_system_store => $use_system_store,
      initial_org      => $initial_org,
      token_file       => $influxdb_token_file,
    }

    influxdb_org { $initial_org:
      ensure           => present,
      use_ssl          => $use_ssl,
      use_system_store => $use_system_store,
      port             => $influxdb_port,
      token            => $influxdb_token,
      token_file       => $influxdb_token_file,
      require          => Class['influxdb'],
    }
    influxdb_bucket { $initial_bucket:
      ensure           => present,
      use_ssl          => $use_ssl,
      use_system_store => $use_system_store,
      port             => $influxdb_port,
      org              => $initial_org,
      token            => $influxdb_token,
      retention_rules  => $influxdb_bucket_retention_rules,
      token_file       => $influxdb_token_file,
      require          => [Class['influxdb'], Influxdb_org[$initial_org]],
    }

    Influxdb_auth {
      require => Class['influxdb'],
    }
  }

  if $manage_telegraf_token {
    # Create a token with permissions to read and write timeseries data
    # The influxdb::retrieve_token() function cannot find a token during the catalog compilation which creates it
    #   i.e. it takes two agent runs to become available
    influxdb_auth { $telegraf_token_name:
      ensure           => present,
      use_ssl          => $use_ssl,
      use_system_store => $use_system_store,
      port             => $influxdb_port,
      org              => $initial_org,
      token            => $influxdb_token,
      token_file       => $influxdb_token_file,
      permissions      => [
        {
          'action'   => 'read',
          'resource' => {
            'type'   => 'telegrafs',
          }
        },
        {
          'action'   => 'write',
          'resource' => {
            'type'   => 'telegrafs',
          }
        },
        {
          'action'   => 'read',
          'resource' => {
            'type'   => 'buckets',
          }
        },
        {
          'action'   => 'write',
          'resource' => {
            'type'   => 'buckets',
          }
        },
      ],
    }
  }

  if $manage_telegraf {
    include 'puppet_operational_dashboards::telegraf::agent'
  }

  include 'puppet_operational_dashboards::profile::dashboards'
}
