# @summary Installs dependancies for Operational dashboards on PE infrastructure components
#
# When applied to an appropriate node group this class applies the toml gem and database access
# On appropriate infrastructure nodes in PE
#
# @example
#   include puppet_operational_dashboards::enterprise_infrastructure
# @param profiles
#   Array of PE profiles on the node with this class applied. 
class puppet_operational_dashboards::enterprise_infrastructure (
  Array[String] $profiles = puppet_operational_dashboards::pe_profiles_on_host(),
) {
  if   ('Puppet_enterprise::Profile::Master' in $profiles) {
    include influxdb::profile::toml
  }

  if  ('Puppet_enterprise::Profile::Database' in $profiles) {
    include puppet_operational_dashboards::profile::postgres_access
  }
}
