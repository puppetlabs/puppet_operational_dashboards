# @summary function used to determine hosts with a Puppet Enterprise profile
#
# Queries PuppetDB for hosts with the specified Puppet Enterprise profile.
# Used by this module to identify hosts with Puppet Enterprise API endpoints.
#
# @param profile [String]
#   The short name of the Puppet Enterprise profile to query.
#
# @return [Array[String]]
#   An array of certnames from the query, or the local certname when the query returns no hosts.

function puppet_operational_dashboards::pe_profiles_on_host() >> Array {
  if $settings::storeconfigs {
    $hosts = puppetdb_query("resources[title] {
      type = 'Class' and
      certname = '${trusted['certname']}' and
      title in ['Puppet_enterprise::Profile::Puppetdb', 'Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Database'] and
      nodes { deactivated is null and expired is null }
    }").map |$nodes| { $nodes['title'] }
  } else {
    $hosts = []
  }
  $hosts
}
