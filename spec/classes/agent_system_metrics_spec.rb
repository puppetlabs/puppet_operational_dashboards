require 'spec_helper'

describe 'puppet_operational_dashboards::telegraf::system_metrics' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'when using default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__input('cpu_metrics') }
        it { is_expected.to contain_telegraf__input('disk_metrics') }
        it { is_expected.to contain_telegraf__input('filestat_metrics') }
        it { is_expected.to contain_telegraf__input('internal_metrics') }
        it { is_expected.to contain_telegraf__input('interrupts_metrics') }
        it { is_expected.to contain_telegraf__input('kernel_metrics') }
        it { is_expected.to contain_telegraf__input('kernel_vmstat_metrics') }
        it { is_expected.to contain_telegraf__input('linux_sysctl_fs_metrics') }
        it { is_expected.to contain_telegraf__input('mem_metrics') }
        it { is_expected.to contain_telegraf__input('net_metrics') }
        it { is_expected.to contain_telegraf__input('netstat_metrics') }
        it { is_expected.to contain_telegraf__input('nstat_metrics') }
        it { is_expected.to contain_telegraf__input('processes_metrics') }
        it { is_expected.to contain_telegraf__input('swap_metrics') }
        it { is_expected.to contain_telegraf__input('system_metrics') }
        it { is_expected.to contain_telegraf__input('systemd_units_metrics') }
      end
    end
  end
end
