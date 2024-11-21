# @summary Installs dependancies for Operational dashboards on PE infrastructure components
#
# When applied to an appropriate node group this class applies the toml gem and database access
# On appropriate infrastructure nodes in PE
#
# @example
#   include puppet_operational_dashboards::enterprise_infrastructure
# @param profiles
#   Array of PE profiles on the node with this class applied.
# @param template_format
#   Template format to use for puppet template toml or yaml config
class puppet_operational_dashboards::enterprise_infrastructure (
  Array[String] $profiles              = puppet_operational_dashboards::pe_profiles_on_host(),
  Enum['yaml','toml'] $template_format = 'toml',
) {
  if   ('Puppet_enterprise::Profile::Master' in $profiles) and ($template_format == 'toml') {
    include influxdb::profile::toml
  }

  if  ('Puppet_enterprise::Profile::Database' in $profiles) {
    include puppet_operational_dashboards::profile::postgres_access
  }
}
