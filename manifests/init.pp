# @summary Installs Telegraf, InfluxDB, and Grafana to collect and display Puppet metrics
# @example Basic usage
#   include puppet_operational_dashboards
#
#   class {'puppet_operational_dashboards':
#     manage_influxdb => false,
#     influxdb_host   => '<influxdb_fqdn>',
#   }
# @param manage_influxdb
#   Whether to manage installation and configuration of InfluxDB.  Defaults to true
# @param manage_grafana
#   Whether to manage installation and configuration of Grafana.  Defaults to true
# @param influxdb_host
#   FQDN of the InfluxDB host.  Defaults to a the value of influxdb::host, or $facts['fqdn'] if unset
# @param influxdb_port
#   Port used by the InfluxDB service.  Defaults to the value of influxdb::port, or 8086 if unset
# @param initial_org
#   Name of the InfluxDB organization to configure. Defaults to the value of influxdb::initial_org, or 'puppetlabs' if unset
# @param initial_bucket
#   Name of the InfluxDB bucket to configure and query. Defaults to the value of influxdb::initial_bucket, or 'puppet_data' if unset
# @param influxdb_token
#   InfluxDB admin token in Sensitive format.  Defaults to the value of influxdb::token.
#   See the puppetlabs/influxdb documentation for more information about this token.
# @param telegraf_token
#   Telegraf token in Sensitive format.  This parameter is preferred over $telegraf_token_name if both are given
# @param telegraf_token_name
#   Name of the token to retrieve from InfluxDB if not given $telegraf_token.
# @param manage_telegraf
#   Whether to manage installation and configuration of Telegraf.  Defaults to true.
# @param manage_telegraf_token
#   Whether to create and manage a Telegraf token with permissions to query buckets in the default organization.  Defaults to true.
# @param use_ssl
#   Whether to use SSL when querying InfluxDB.  Defaults to true
class puppet_operational_dashboards (
  Boolean $manage_influxdb = true,
  Boolean $manage_grafana = true,
  String $influxdb_host = lookup(influxdb::host, undef, undef, $facts['fqdn']),
  Integer $influxdb_port = lookup(influxdb::port, undef, undef, 8086),
  String $initial_org = lookup(influxdb::initial_org, undef, undef, 'puppetlabs'),
  String $initial_bucket = lookup(influxdb::initial_bucket, undef, undef, 'puppet_data'),

  Optional[Sensitive[String]] $influxdb_token = lookup(influxdb::token, undef, undef, undef),
  Optional[Sensitive[String]] $telegraf_token = undef,
  # Name of the token to retrive from InfluxDB using the retrieve_token() function if not given $telegraf_token
  String $telegraf_token_name = 'puppet telegraf token',

  Boolean $manage_telegraf = true,
  Boolean $manage_telegraf_token = true,
  Boolean $use_ssl = true,
) {

  unless $facts['os']['family'] in ['RedHat', 'Debian', 'Suse'] {
    fail("Installation on ${facts['os']['family']} is not supported")
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }
  $influxdb_uri = "${protocol}://${influxdb_host}:${influxdb_port}"

  #TODO: how to check for this without failing compilation
  if !file('/opt/puppetlabs/server/data/puppetserver/jruby-gems/gems/toml-rb-2.1.1/README.md') {
    notify {'toml_gem_warn':
      message  => 'toml-rb gem not found. Please see the README for how to install the correct version of the gem.',
      loglevel => 'warning',
    }
  }
  else {
    if $manage_influxdb {
      class {'influxdb':
        host        => $influxdb_host,
        port        => $influxdb_port,
        initial_org => $initial_org,
      }

      influxdb_org {$initial_org:
        ensure  => present,
        token   => $influxdb_token,
        require => Class['influxdb'],
      }
      influxdb_bucket {$initial_bucket:
        ensure  => present,
        org     => $initial_org,
        token   => $influxdb_token,
        require => [Class['influxdb'], Influxdb_org[$initial_org]],
      }

      Influxdb_auth {
        require => Class['influxdb'],
      }
    }

    if $manage_telegraf_token {
      # Create a token with permissions to read and write timeseries data
      # The influxdb::retrieve_token() function cannot find a token during the catalog compilation which creates it
      #   i.e. it takes two agent runs to become available
      influxdb_auth {$telegraf_token_name:
        ensure      => present,
        org         => $initial_org,
        token       => $influxdb_token,
        permissions => [
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'telegrafs'
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'telegrafs'
            }
          },
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'buckets'
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'buckets'
            }
          },
        ],
      }
    }

    if $manage_telegraf {
      $telegraf_token_contents = if $telegraf_token {
        $telegraf_token
      }
      elsif $influxdb_token {
        Sensitive(influxdb::retrieve_token($influxdb_uri, $influxdb_token, $telegraf_token_name))
      }
      else {
        undef
      }

      if $telegraf_token_contents {
        class {'puppet_operational_dashboards::telegraf::agent':
          token => $telegraf_token_contents
        }
      }
      else {
        notify {'puppet_telegraf_token_warn':
          message  => 'Please set either influxdb::token or puppet_operational_dashboards::telegraf_token to complete installation',
          loglevel => 'warning'
        }
      }
    }
  }

  if $telegraf_token_contents {
    class {'puppet_operational_dashboards::profile::dashboards':
      token => $telegraf_token_contents
    }
  }
}
