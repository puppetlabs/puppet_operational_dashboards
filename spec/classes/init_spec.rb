require 'spec_helper'

describe 'puppet_operational_dashboards' do
  let(:facts) { { os: { family: 'RedHat' } } }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end

  context 'when using default parameters' do
    let(:params) { { influxdb_host: 'localhost' } }

    it {
      is_expected.to contain_class('puppet_operational_dashboards::profile::dashboards')
      is_expected.to contain_class('puppet_operational_dashboards::telegraf::agent')

      is_expected.to contain_class('influxdb').with(
        host: 'localhost',
        port: 8086,
        use_ssl: true,
        initial_org: 'puppetlabs',
        token: nil,
        token_file: '/root/.influxdb_token',
      )

      is_expected.to contain_influxdb_org('puppetlabs').that_requires('Class[influxdb]')
      is_expected.to contain_influxdb_org('puppetlabs').with(
        ensure: 'present',
        token: nil,
        token_file: '/root/.influxdb_token',
      )

      is_expected.to contain_influxdb_bucket('puppet_data').that_requires('Class[influxdb]')
      is_expected.to contain_influxdb_bucket('puppet_data').with(
        ensure: 'present',
        token: nil,
        token_file: '/root/.influxdb_token',
      )

      is_expected.to contain_influxdb_auth('puppet telegraf token').with(
        ensure: 'present',
        org: 'puppetlabs',
        token: nil,
        token_file: '/root/.influxdb_token',
        permissions: [
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'telegrafs',
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'telegrafs',
            }
          },
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'buckets',
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'buckets',
            }
          },
        ],
      )

      is_expected.to contain_service('influxdb').with_ensure('running')
    }
  end

  context 'when not using ssl' do
    let(:params) { { influxdb_host: 'localhost', use_ssl: false } }

    it { is_expected.to contain_class('influxdb').with(use_ssl: false) }
  end

  context 'when not managing influxdb' do
    let(:params) { { influxdb_host: 'localhost', manage_influxdb: false } }

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
    let(:params) { { manage_telegraf: false } }

    it {
      is_expected.not_to contain_class('puppet_operational_dashboards::telegraf::agent')
    }
  end

  context 'when not managing telegraf token' do
    let(:params) { { manage_telegraf_token: false } }

    it {
      is_expected.not_to contain_influxdb_auth('puppet telegraf token')
    }
  end

  context 'when passing a token' do
    let(:params) { { influxdb_host: 'localhost', influxdb_token: RSpec::Puppet::Sensitive.new('puppetlabs') } }

    it {
      is_expected.to contain_influxdb_org('puppetlabs').with(token: RSpec::Puppet::Sensitive.new('puppetlabs'))
      is_expected.to contain_influxdb_bucket('puppet_data').with(token: RSpec::Puppet::Sensitive.new('puppetlabs'))
      is_expected.to contain_influxdb_auth('puppet telegraf token').with(token: RSpec::Puppet::Sensitive.new('puppetlabs'))
    }
  end
end
