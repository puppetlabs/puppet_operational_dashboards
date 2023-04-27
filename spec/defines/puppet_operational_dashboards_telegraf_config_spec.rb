require 'spec_helper'
require 'json'

describe 'puppet_operational_dashboards::telegraf::config' do
  let(:facts) { { os: { family: 'RedHat' } } }
  let(:params) do
    {
      ensure: 'present',
      protocol: 'https',
      http_timeout_seconds: 5,
      hosts: ['localhost.foo.com'],
      puppet_ssl_cert_file: '/etc/telegraf/cert.pem',
      puppet_ssl_key_file: '/etc/telegraf/key.pem',
      puppet_ssl_ca_file: '/etc/telegraf/ca.pem',
    }
  end

  context 'when puppetserver' do
    let(:title) { 'puppetserver' }
    let(:puppetserver_epp) do
      JSON.parse(File.read('./spec/fixtures/defines/puppetserver_metrics.json'))
    end

    it {
      is_expected.to compile

      is_expected.to contain_telegraf__input('puppetserver_metrics').with(
        {
          name: 'puppetserver_metrics',
          plugin_type: 'http',
          options: puppetserver_epp,
        },
      )

      is_expected.to contain_telegraf__processor('puppetserver_renames').with(
        ensure: 'present',
        name: 'puppetserver_renames',
        plugin_type: 'strings',
        options: [
          'replace' => [{
            'tag' => 'url',
            'old' => 'https://localhost.foo.com:8140/status/v1/services?level=debug',
            'new' => 'localhost.foo.com'
          }],
        ],
      )
    }
  end

  context 'when puppetdb' do
    let(:title) { 'puppetdb' }
    # Giant array of the rendered toml template
    let(:puppetdb_epp) do
      JSON.parse(File.read('./spec/fixtures/defines/puppetdb_metrics.json'))
    end

    it {
      is_expected.to compile

      is_expected.to contain_telegraf__input('puppetdb_metrics').with(
        {
          name: 'puppetdb_metrics',
          plugin_type: 'http',
          options: puppetdb_epp,
        },
      )

      is_expected.to contain_telegraf__processor('puppetdb_renames').with(
        ensure: 'present',
        name: 'puppetdb_renames',
        plugin_type: 'strings',
        options: [
          'replace' => [{
            'tag' => 'url',
            'old' => 'https://localhost.foo.com:8081/metrics/v2/read',
            'new' => 'localhost.foo.com'
          }],
        ],
      )

      is_expected.to contain_telegraf__processor('puppetdb_mbean_renames').with(
        ensure: 'present',
        name: 'puppetdb_mbean_renames',
        plugin_type: 'regex',
        options: [
          {
            'tags' => [
              {
                'key' => 'mbean',
                'append' => false,
                'pattern' => '.*name=(?P<name>.+)',
                'replacement' => '${name}'
              },
            ]
          },
        ],
      )
    }
  end

  context 'when puppetdb_jvm' do
    let(:title) { 'puppetdb_jvm' }
    let(:puppetdb_jvm_epp) do
      JSON.parse(File.read('./spec/fixtures/defines/puppetdb_jvm_metrics.json'))
    end

    it {
      is_expected.to compile

      is_expected.to contain_telegraf__input('puppetdb_jvm_metrics').with(
        {
          name: 'puppetdb_jvm_metrics',
          plugin_type: 'http',
          options: puppetdb_jvm_epp,
        },
      )

      is_expected.to contain_telegraf__processor('puppetdb_jvm_renames').with(
        ensure: 'present',
        name: 'puppetdb_jvm_renames',
        plugin_type: 'strings',
        options: [
          'replace' => [{
            'tag' => 'url',
            'old' => 'https://localhost.foo.com:8081/status/v1/services?level=debug',
            'new' => 'localhost.foo.com'
          }],
        ],
      )
    }
  end

  context 'when not using ssl' do
    let(:title) { 'puppetserver' }
    let(:params) do
      {
        ensure: 'present',
        protocol: 'http',
        http_timeout_seconds: 5,
        hosts: ['localhost.foo.com'],
        puppet_ssl_cert_file: '/etc/telegraf/cert.pem',
        puppet_ssl_key_file: '/etc/telegraf/key.pem',
        puppet_ssl_ca_file: '/etc/telegraf/ca.pem',  
      }
    end

    let(:puppetserver_epp) do
      JSON.parse(File.read('./spec/fixtures/defines/puppetserver_metrics_no_ssl.json'))
    end

    it {
      is_expected.to compile

      is_expected.to contain_telegraf__input('puppetserver_metrics').with(
        {
          name: 'puppetserver_metrics',
          plugin_type: 'http',
          options: puppetserver_epp,
        },
      )

      is_expected.to contain_telegraf__processor('puppetserver_renames').with(
        ensure: 'present',
        name: 'puppetserver_renames',
        plugin_type: 'strings',
        options: [
          'replace' => [{
            'tag' => 'url',
            'old' => 'http://localhost.foo.com:8140/status/v1/services?level=debug',
            'new' => 'localhost.foo.com'
          }],
        ],
      )
    }
  end
end
