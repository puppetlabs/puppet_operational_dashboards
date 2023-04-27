# @summary Defined type to create Telegraf configurations for a given service
# @param service
#   Name of the service to query.  Is the title of the resource.
# @param protocol
#   Protocol to use in requests, either https or http
# @param hosts
#   Array of hosts running the service
# @param ensure
#   Whether the resource should be present or absent
# @param http_timeout_seconds
#   Timeout for HTTP Telegraf inputs. Might be usefull in huge environments with slower API responses
# @param puppet_ssl_ca_file
#   CA file to use when connecting to puppet services
# @param puppet_ssl_cert_file
#   Cert to use when connecting to puppet services
# @param puppet_ssl_key_file
#   Key to use when connecting to Puppet services
define puppet_operational_dashboards::telegraf::config (
  Array[String[1]] $hosts,
  Enum['https', 'http'] $protocol,
  Integer[1] $http_timeout_seconds,
  String $service = $title,
  Enum['present', 'absent'] $ensure = 'present',
  Stdlib::Absolutpath $puppet_ssl_ca_file = $puppet_operational_dashboards::telegraf::agent::puppet_ssl_ca_file,
  Stdlib::Absolutpath $puppet_ssl_cert_file = puppet_operational_dashboards::telegraf::agent::puppet_ssl_cert_file,
  Stdlib::Absolutpath $puppet_ssl_key_file = puppet_operational_dashboards::telegraf::agent::puppet_ssl_key_file,
) {
  unless $service in ['puppetserver', 'puppetdb', 'puppetdb_jvm', 'orchestrator'] {
    fail("Unknown service type ${service}")
  }

  if $ensure == 'present' {
    $path = $service ? {
      'puppetdb'     => '8081/metrics/v2/read',
      'puppetdb_jvm'     => '8081/status/v1/services?level=debug',
      'puppetserver'     => '8140/status/v1/services?level=debug',
      'orchestrator'     => '8143/status/v1/services?level=debug',
    }

    # Create a urls[] array with literal quotes around each entry
    $urls = $hosts.map |$host| { "\"${protocol}://${host}:${path}\"" }

    $inputs = epp(
      "puppet_operational_dashboards/${service}_metrics.epp",
        {
          urls                 => $urls,
          protocol             => $protocol,
          http_timeout_seconds => $http_timeout_seconds,
          puppet_ssl_ca_file   => $puppet_ssl_ca_file,
          puppet_ssl_cert_file => $puppet_ssl_cert_file,
          puppet_ssl_key_file  => $puppet_ssl_key_file,
        }
    ).influxdb::from_toml()

    telegraf::input { "${service}_metrics":
      plugin_type => 'http',
      options     => [$inputs],
    }

    # Create processors.strings.rename entries to rename full url to hostname
    $renames = {
      'replace' => $hosts.map |$host| {
        {
          'tag'  => 'url',
          'old'  => "${protocol}://${host}:${path}",
          'new'  => $host,
        }
      },
    }

    telegraf::processor { "${service}_renames":
      plugin_type => 'strings',
      options     => [$renames],
    }

    if $service == 'puppetdb' {
      $regexes = {
        tags => [{
            'key'         => 'mbean',
            'append'      => false,
            'pattern'     => '.*name=(?P<name>.+)',
            # This is the name of a regex capture group, not a variable
            'replacement' => '${name}', # lint:ignore:single_quote_string_with_variables
        }],
      }

      telegraf::processor { 'puppetdb_mbean_renames':
        plugin_type => 'regex',
        options     => [$regexes],
      }
    }
  }
  else {
    telegraf::processor { "${service}_renames":
      ensure => absent,
    }

    telegraf::input { "${service}_metrics":
      ensure => absent,
    }
  }
}
