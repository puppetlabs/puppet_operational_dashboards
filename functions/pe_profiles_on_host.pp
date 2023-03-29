# @summary function used to determine hosts with a Puppet Enterprise profile
#
# Queries PuppetDB for Puppet Enterprise profile on the node including the class.
# Used by this module to identify Puppet Enterprise API endpoints on the node.
#
# @return [Array[String]]
#   An array of PE profiles representing the Puppet server, PDB, and postgres services
function puppet_operational_dashboards::pe_profiles_on_host() >> Array[String] {
  if $settings::storeconfigs {
  $hosts = puppetdb_query("resources[title] {
      type = 'Class' and
      certname = '${trusted['certname']}' and
      title in ['Puppet_enterprise::Profile::Puppetdb', 'Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Database', 'Puppet_enterprise::Profile::Orchestrator'] and
      nodes { deactivated is null and expired is null }
    }").map |$nodes| { $nodes['title'] }
  } else {
    $hosts = []
  }
  $hosts
}
