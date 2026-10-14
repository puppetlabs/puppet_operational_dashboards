# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards' do
  let(:telegraf_permissions) do
    [
      { 'action' => 'read', 'resource' => { 'type' => 'telegrafs' } },
      { 'action' => 'write', 'resource' => { 'type' => 'telegrafs' } },
      { 'action' => 'read', 'resource' => { 'type' => 'buckets' } },
      { 'action' => 'write', 'resource' => { 'type' => 'buckets' } },
    ]
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards') }
      it { is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent') }
    end
  end

  context 'with default facts' do
    let(:facts) { on_supported_os['redhat-9-x86_64'] }

    context 'when using default parameters' do
      let(:params) { { influxdb_host: 'localhost', include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('influxdb').with(
          host: 'localhost',
          port: 8086,
          use_ssl: true,
          use_system_store: false,
          initial_org: 'puppetlabs',
          token: nil,
          token_file: '/root/.influxdb_token',
        )
      }

      it {
        is_expected.to contain_influxdb_org('puppetlabs').that_requires('Class[influxdb]')
        is_expected.to contain_influxdb_org('puppetlabs').with(
          ensure: 'present',
          use_ssl: true,
          use_system_store: false,
          port: 8086,
          token: nil,
          token_file: '/root/.influxdb_token',
        )
      }

      it {
        is_expected.to contain_influxdb_bucket('puppet_data').that_requires(['Class[influxdb]', 'Influxdb_org[puppetlabs]'])
        is_expected.to contain_influxdb_bucket('puppet_data').with(
          ensure: 'present',
          org: 'puppetlabs',
          port: 8086,
          token: nil,
          token_file: '/root/.influxdb_token',
          retention_rules: [{ 'type' => 'expire', 'everySeconds' => 7_776_000, 'shardGroupDurationSeconds' => 604_800 }],
        )
      }

      it {
        is_expected.to contain_influxdb_auth('puppet telegraf token').with(
          ensure: 'present',
          use_ssl: true,
          use_system_store: false,
          port: 8086,
          org: 'puppetlabs',
          token: nil,
          token_file: '/root/.influxdb_token',
          permissions: telegraf_permissions,
        )
        # The resource default in the class adds a require on the influxdb class when it is managed
        is_expected.to contain_influxdb_auth('puppet telegraf token').that_requires('Class[influxdb]')
      }

      it { is_expected.to contain_service('influxdb').with_ensure('running') }
    end

    context 'when customizing the InfluxDB organization, bucket, and port' do
      let(:params) do
        {
          influxdb_host: 'foo.bar.com',
          influxdb_port: 9999,
          initial_org: 'myorg',
          initial_bucket: 'mybucket',
          influxdb_bucket_retention_rules: [{ 'type' => 'expire', 'everySeconds' => 86_400 }],
          telegraf_token_name: 'custom token',
          include_pe_metrics: true,
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('influxdb').with(host: 'foo.bar.com', port: 9999, initial_org: 'myorg') }
      it { is_expected.to contain_influxdb_org('myorg').with(port: 9999) }

      it {
        is_expected.to contain_influxdb_bucket('mybucket').with(
          org: 'myorg',
          port: 9999,
          retention_rules: [{ 'type' => 'expire', 'everySeconds' => 86_400 }],
        ).that_requires('Influxdb_org[myorg]')
      }

      it { is_expected.to contain_influxdb_auth('custom token').with(org: 'myorg', port: 9999) }

      it 'passes the customized values to the included classes' do
        is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent').with(
          influxdb_host: 'foo.bar.com',
          influxdb_port: 9999,
          influxdb_org: 'myorg',
          influxdb_bucket: 'mybucket',
          token_name: 'custom token',
        )
        is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards').with(
          influxdb_host: 'foo.bar.com',
          influxdb_port: 9999,
          influxdb_bucket: 'mybucket',
          telegraf_token_name: 'custom token',
        )
      end
    end

    context 'when managing InfluxDB on a remote host' do
      let(:params) { { influxdb_host: 'influx.example.com', include_pe_metrics: true } }

      it { is_expected.to compile.and_raise_error(%r{Unable to manage InfluxDB installation on host: influx\.example\.com}) }
    end

    context 'when using a remote InfluxDB host without managing InfluxDB' do
      let(:params) { { influxdb_host: 'influx.example.com', manage_influxdb: false, include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_influxdb_auth('puppet telegraf token') }
      it 'points telegraf at the remote InfluxDB host' do
        outputs = catalogue.resource('Class', 'telegraf')[:outputs]
        expect(outputs['influxdb_v2'].first['urls']).to eq(['https://influx.example.com:8086'])
      end
    end

    context 'when using the system CA store' do
      let(:params) { { influxdb_host: 'localhost', use_system_store: true, include_pe_metrics: true } }

      it { is_expected.to contain_class('influxdb').with(use_system_store: true) }
      it { is_expected.to contain_influxdb_org('puppetlabs').with(use_system_store: true) }
      it { is_expected.to contain_influxdb_bucket('puppet_data').with(use_system_store: true) }
      it { is_expected.to contain_influxdb_auth('puppet telegraf token').with(use_system_store: true) }
    end

    context 'when not using ssl' do
      let(:params) { { influxdb_host: 'localhost', use_ssl: false, include_pe_metrics: true } }

      it { is_expected.to contain_class('influxdb').with(use_ssl: false) }
      it { is_expected.to contain_influxdb_org('puppetlabs').with(use_ssl: false) }
      it { is_expected.to contain_influxdb_bucket('puppet_data').with(use_ssl: false) }
      it { is_expected.to contain_influxdb_auth('puppet telegraf token').with(use_ssl: false) }
    end

    context 'when not managing influxdb' do
      let(:params) { { influxdb_host: 'localhost', manage_influxdb: false, include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.not_to contain_class('influxdb')
        is_expected.not_to contain_influxdb_org('puppetlabs')
        is_expected.not_to contain_influxdb_bucket('puppet_data')

        # We should still be managing the token, but without a require on the class
        is_expected.to contain_influxdb_auth('puppet telegraf token')
        is_expected.not_to contain_influxdb_auth('puppet telegraf token').that_requires('Class[influxdb]')
      }
    end

    context 'when not managing telegraf' do
      let(:params) { { manage_telegraf: false, include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_class('puppet_operational_dashboards::telegraf::agent') }
      it { is_expected.not_to contain_class('telegraf') }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards') }
    end

    context 'when not managing telegraf token' do
      let(:params) { { manage_telegraf_token: false, include_pe_metrics: true } }

      it { is_expected.not_to contain_influxdb_auth('puppet telegraf token') }
    end

    context 'when passing a token' do
      let(:params) { { influxdb_host: 'localhost', influxdb_token: sensitive('puppetlabs'), include_pe_metrics: true } }

      it {
        is_expected.to contain_influxdb_org('puppetlabs').with(token: sensitive('puppetlabs'))
        is_expected.to contain_influxdb_bucket('puppet_data').with(token: sensitive('puppetlabs'))
        is_expected.to contain_influxdb_auth('puppet telegraf token').with(token: sensitive('puppetlabs'))
      }
    end

    context 'when passing a telegraf token' do
      let(:params) { { influxdb_host: 'localhost', telegraf_token: sensitive('telegraf'), include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent').with(token: sensitive('telegraf')) }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards').with(token: sensitive('telegraf')) }
    end

    context 'when using the yaml template format' do
      let(:params) { { influxdb_host: 'localhost', template_format: 'yaml', include_pe_metrics: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent').with(template_format: 'yaml') }
    end

    context 'when not including PE metrics' do
      let(:params) { { influxdb_host: 'localhost', include_pe_metrics: false } }

      it { is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent').with(include_pe_metrics: false) }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards').with(include_pe_metrics: false) }
    end

    context 'when not managing the system dashboard' do
      let(:params) { { influxdb_host: 'localhost', manage_system_board: false, include_pe_metrics: true } }

      it { is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards').with(manage_system_board: false) }
    end
  end

  context 'when the agent runs as a non-root user' do
    let(:facts) { on_supported_os['redhat-9-x86_64'].merge(identity: { 'user' => 'pe-puppet' }) }
    let(:params) { { influxdb_host: 'localhost', include_pe_metrics: true } }

    it { is_expected.to contain_class('influxdb').with(token_file: '/home/pe-puppet/.influxdb_token') }
    it { is_expected.to contain_influxdb_auth('puppet telegraf token').with(token_file: '/home/pe-puppet/.influxdb_token') }
  end

  context 'on an unsupported operating system family' do
    let(:facts) { on_supported_os['redhat-9-x86_64'].merge(os: { 'family' => 'Windows', 'name' => 'windows' }) }

    it { is_expected.to compile.and_raise_error(%r{Installation on Windows is not supported}) }
  end
end
