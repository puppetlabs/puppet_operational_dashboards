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
# @param template_format
#   Template format to use for puppet template toml or yaml config
define puppet_operational_dashboards::telegraf::config (
  Array[String[1]] $hosts,
  Enum['https', 'http'] $protocol,
  Integer[1] $http_timeout_seconds,
  String $service = $title,
  Enum['present', 'absent'] $ensure = 'present',
  Enum['yaml','toml'] $template_format = 'toml',
) {
  unless $service in ['puppetserver', 'puppetdb', 'puppetdb_jvm', 'orchestrator', 'pcp'] {
    fail("Unknown service type ${service}")
  }

  if $ensure == 'present' {
    $path = $service ? {
      'puppetdb'     => '8081/metrics/v2/read',
      'puppetdb_jvm' => '8081/status/v1/services?level=debug',
      'puppetserver' => '8140/status/v1/services?level=debug',
      'orchestrator' => '8143/status/v1/services?level=debug',
      # The class that includes this defined type specifies the port accordingly
      'pcp'          => 'metrics/v2/read/default:name=puppetlabs.pcp.connections',
    }

    # Create a urls[] array with literal quotes around each entry
    if $service == 'pcp' {
      $urls = $hosts.map |$host| { "\"${protocol}://${host}/${path}\"" }
    }
    else {
      $urls = $hosts.map |$host| { "\"${protocol}://${host}:${path}\"" }
    }

    $inputs = epp(
      "puppet_operational_dashboards/${service}_metrics.${template_format}.epp",
      { urls => $urls, protocol => $protocol, http_timeout_seconds => $http_timeout_seconds }
    )

    $_inputs = $template_format ? {
      'yaml'  => $inputs.parseyaml(),
      default => $inputs.influxdb::from_toml(),
    }

    telegraf::input { "${service}_metrics":
      plugin_type => 'http',
      options     => [$_inputs],
    }

    # Create processors.strings.rename entries to rename full url to hostname
    if $service == 'pcp' {
      $renames = {
        'replace' => $hosts.map |$host| {
          {
            'tag'  => 'url',
            'old'  => "${protocol}://${host}/${path}",
            'new'  => $host.split(':')[0],
          }
        },
      }
    }
    else {
      $renames = {
        'replace' => $hosts.map |$host| {
          {
            'tag'  => 'url',
            'old'  => "${protocol}://${host}:${path}",
            'new'  => $host,
          }
        },
      }
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
