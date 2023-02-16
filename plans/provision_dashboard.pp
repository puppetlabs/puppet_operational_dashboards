# @summary A plan to provision a non-SSL operational dashboards node
# @param targets The targets to run on.
plan puppet_operational_dashboards::provision_dashboard (
  TargetSpec $targets
) {
  $targets.apply_prep

  apply ($targets) {
    class { 'puppet_operational_dashboards':
      use_ssl => false,
    }
  }
  # Apply the class twice so we can use the token created by the first application
  apply ($targets) {
    class { 'puppet_operational_dashboards':
      use_ssl => false,
    }
  }
}
