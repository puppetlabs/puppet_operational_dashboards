#
# @summary configures additional inputs for telegraf to collect system information
#
# @param telegraf_inputs hash of all inputs that should be configured
#
class puppet_operational_dashboards::telegraf::system_metrics (
  Hash[String[1], Hash[String[1],NotUndef]] $telegraf_inputs = {
    'cpu' => {},
    'disk' => { 'options' => [{ 'ignore_fs' => ['tmpfs', 'devtmpfs', 'devfs', 'iso9660', 'overlay', 'aufs', 'squashfs', 'nfs4', 'autofs', 'nfs'] }] },
    'filestat' => {},
    'internal' => {},
    'interrupts' => {},
    'kernel' => {},
    'kernel_vmstat' => {},
    'linux_sysctl_fs' => {},
    'mem' => {},
    'net' => {},
    'netstat' => {},
    'nstat' => {},
    'processes' => {},
    'swap' => {},
    'system' => {},
    'systemd_units' => {},
  }
) {
  $telegraf_inputs.each |$input, $data| {
    # to make a simple plugin work, it needs: options =>  { [ ] }
    # because we don't want to hardcode it in $telegraf_inputs every time, we generate it here if options isn't set already
    $_options = $data['options']  ? {
      undef => [{}],
      default => $data['options'],
    }

    $_data = delete($data, 'options')

    telegraf::input { "${input}_metrics":
      plugin_type => $input,
      options     => $_options,
      *           => $_data,
    }
  }
}
