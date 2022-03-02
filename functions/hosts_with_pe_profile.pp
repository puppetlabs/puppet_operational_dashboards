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

function puppet_operational_dashboards::hosts_with_pe_profile(
  String $profile,
) >> Array {
  if $settings::storeconfigs {
    $hosts = puppetdb_query("resources[certname] {
      type = 'Class' and
      title = 'Puppet_enterprise::Profile::${profile}' and
      nodes { deactivated is null and expired is null }
    }").map |$nodes| { $nodes['certname'] }
  } else {
    $hosts = []
  }
  if empty($hosts) {
    [$trusted['certname']]
  } else {
    sort($hosts)
  }
}
