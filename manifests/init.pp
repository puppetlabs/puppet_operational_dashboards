class puppet_operational_dashboards (
  Boolean $manage_influxdb = true,
  Boolean $manage_grafana = true,
  String $influxdb_host = lookup(influxdb::host, undef, undef, $facts['fqdn']),
  Integer $influxdb_port = lookup(influxdb::port, undef, undef, 8086),

  Optional[Sensitive[String]] $influxdb_token = lookup(influxdb::token, undef, undef, undef),
  Optional[Sensitive[String]] $telegraf_token = undef,
  String $initial_org = lookup(influxdb::initial_org, undef, undef, 'puppetlabs'),
  String $initial_bucket = lookup(influxdb::initial_bucket, undef, undef, 'puppet_data'),
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
        token       => $influxdb_token,
        require => Class['influxdb'],
      }
      influxdb_bucket {$initial_bucket:
        ensure  => present,
        org     => $initial_org,
        token       => $influxdb_token,
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
        influxdb::retrieve_token($influxdb_uri, $influxdb_token, $telegraf_token_name)
      }
      else {
        undef
      }

      if $telegraf_token_contents {
        class {'puppet_operational_dashboards::telegraf::agent':
          token => $telegraf_token_contents ? {
            Sensitive => $telegraf_token_contents,
            default   => Sensitive($telegraf_token_contents)
          }
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
      token => $telegraf_token_contents ? {
        Sensitive => $telegraf_token_contents,
        default   => Sensitive($telegraf_token_contents)
      }
    }
  }
}
