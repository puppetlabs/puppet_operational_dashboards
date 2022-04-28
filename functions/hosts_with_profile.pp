# @summary function used to determine hosts with a profile class
#
# Queries PuppetDB for hosts with the specified profile.
# Used by this module to identify hosts with Puppet Enterprise API endpoints and Telegraf hosts
#
# @param profile [String]
#   The full name of the profile to query.
#
# @return [Array[String]]
#   An array of certnames from the query
function puppet_operational_dashboards::hosts_with_profile(
  String $profile,
) >> Array[String] {
  if $settings::storeconfigs {
  puppetdb_query("resources[certname] {
      type = 'Class' and
      title = '${profile}' and
      nodes { deactivated is null and expired is null }
    }").map |$nodes| { $nodes['certname'] }
  } else {
    []
  }
}
