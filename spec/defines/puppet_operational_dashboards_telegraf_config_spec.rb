# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe 'puppet_operational_dashboards::telegraf::config' do
  let(:facts) { on_supported_os['redhat-9-x86_64'] }
  let(:params) do
    {
      ensure: 'present',
      protocol: 'https',
      http_timeout_seconds: 5,
      hosts: ['localhost.foo.com'],
    }
  end

  def fixture(name)
    JSON.parse(File.read(File.join(__dir__, '..', 'fixtures', 'defines', "#{name}.json")))
  end

  # The options parsed from the rendered template, for comparing the toml and yaml formats
  def input_options(service)
    catalogue.resource('Telegraf::Input', "#{service}_metrics")[:options]
  end

  # The puppetdb templates send a JSON request body, which only needs to be equivalent between formats
  def parse_body(options)
    options.map { |o| o.key?('body') ? o.merge('body' => JSON.parse(o['body'])) : o }
  end

  ['toml', 'yaml'].each do |format|
    context "with the #{format} template format" do
      let(:params) { super().merge(template_format: format) }

      context 'when puppetserver' do
        let(:title) { 'puppetserver' }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_telegraf__input('puppetserver_metrics').with(
            plugin_type: 'http',
            options: fixture('puppetserver_metrics'),
          )
        }

        it {
          is_expected.to contain_telegraf__processor('puppetserver_renames').with(
            ensure: 'present',
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

        it { is_expected.not_to contain_telegraf__processor('puppetdb_mbean_renames') }
      end

      context 'when puppetserver without ssl' do
        let(:title) { 'puppetserver' }
        let(:params) { super().merge(protocol: 'http') }

        it { is_expected.to contain_telegraf__input('puppetserver_metrics').with_options(fixture('puppetserver_metrics_no_ssl')) }

        it 'does not configure client certificates' do
          expect(input_options('puppetserver').first.keys).not_to include('tls_cert', 'tls_key', 'tls_ca')
        end

        it {
          is_expected.to contain_telegraf__processor('puppetserver_renames').with_options(
            [
              'replace' => [{
                'tag' => 'url',
                'old' => 'http://localhost.foo.com:8140/status/v1/services?level=debug',
                'new' => 'localhost.foo.com'
              }],
            ],
          )
        }
      end

      context 'when puppetdb' do
        let(:title) { 'puppetdb' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__input('puppetdb_metrics').with_plugin_type('http') }

        it 'requests the same metrics as the fixture' do
          expect(parse_body(input_options('puppetdb'))).to eq(parse_body(fixture('puppetdb_metrics')))
        end

        it {
          is_expected.to contain_telegraf__processor('puppetdb_renames').with(
            ensure: 'present',
            plugin_type: 'strings',
            options: [
              'replace' => [{
                'tag' => 'url',
                'old' => 'https://localhost.foo.com:8081/metrics/v2/read',
                'new' => 'localhost.foo.com'
              }],
            ],
          )
        }

        it {
          is_expected.to contain_telegraf__processor('puppetdb_mbean_renames').with(
            ensure: 'present',
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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__input('puppetdb_jvm_metrics').with(plugin_type: 'http', options: fixture('puppetdb_jvm_metrics')) }

        it {
          is_expected.to contain_telegraf__processor('puppetdb_jvm_renames').with(
            ensure: 'present',
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

        it { is_expected.not_to contain_telegraf__processor('puppetdb_mbean_renames') }
      end

      context 'when orchestrator' do
        let(:title) { 'orchestrator' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__input('orchestrator_metrics').with(plugin_type: 'http', options: fixture('orchestrator_metrics')) }

        it {
          is_expected.to contain_telegraf__processor('orchestrator_renames').with_options(
            [
              'replace' => [{
                'tag' => 'url',
                'old' => 'https://localhost.foo.com:8143/status/v1/services?level=debug',
                'new' => 'localhost.foo.com'
              }],
            ],
          )
        }
      end

      context 'when pcp' do
        let(:title) { 'pcp' }
        # The agent class appends the port to pcp hosts
        let(:params) { super().merge(hosts: ['primary.foo.com:8143', 'compiler.foo.com:8140']) }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__input('pcp_metrics').with(plugin_type: 'http', options: fixture('pcp_metrics')) }

        it 'renames urls to the host name without the port' do
          is_expected.to contain_telegraf__processor('pcp_renames').with_options(
            [
              'replace' => [
                {
                  'tag' => 'url',
                  'old' => 'https://primary.foo.com:8143/metrics/v2/read/default:name=puppetlabs.pcp.connections',
                  'new' => 'primary.foo.com'
                },
                {
                  'tag' => 'url',
                  'old' => 'https://compiler.foo.com:8140/metrics/v2/read/default:name=puppetlabs.pcp.connections',
                  'new' => 'compiler.foo.com'
                },
              ],
            ],
          )
        end
      end

      context 'when querying multiple hosts with a custom timeout' do
        let(:title) { 'puppetserver' }
        let(:params) { super().merge(hosts: ['a.foo.com', 'b.foo.com'], http_timeout_seconds: 30) }

        it {
          options = input_options('puppetserver').first
          expect(options['timeout']).to eq('30s')
          expect(options['urls']).to eq(['https://a.foo.com:8140/status/v1/services?level=debug', 'https://b.foo.com:8140/status/v1/services?level=debug'])
        }

        it {
          renames = catalogue.resource('Telegraf::Processor', 'puppetserver_renames')[:options].first['replace']
          expect(renames.map { |r| r['new'] }).to eq(['a.foo.com', 'b.foo.com'])
        }
      end
    end
  end

  context 'when the service is given as a parameter' do
    let(:title) { 'custom title' }
    let(:params) { super().merge(service: 'puppetserver') }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_telegraf__input('puppetserver_metrics') }
    it { is_expected.to contain_telegraf__processor('puppetserver_renames') }
  end

  context 'when ensure is absent' do
    let(:title) { 'puppetdb' }
    let(:params) { super().merge(ensure: 'absent') }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_telegraf__input('puppetdb_metrics').with_ensure('absent') }
    it { is_expected.to contain_telegraf__processor('puppetdb_renames').with_ensure('absent') }
    it { is_expected.not_to contain_telegraf__processor('puppetdb_mbean_renames') }
  end

  context 'with an unknown service' do
    let(:title) { 'foo' }

    it { is_expected.to compile.and_raise_error(%r{Unknown service type foo}) }
  end

  context 'with an invalid protocol' do
    let(:title) { 'puppetserver' }
    let(:params) { super().merge(protocol: 'ftp') }

    it { is_expected.to compile.and_raise_error(%r{protocol}) }
  end

  context 'with an empty host name' do
    let(:title) { 'puppetserver' }
    let(:params) { super().merge(hosts: ['']) }

    it { is_expected.to compile.and_raise_error(%r{hosts}) }
  end

  context 'with an invalid timeout' do
    let(:title) { 'puppetserver' }
    let(:params) { super().merge(http_timeout_seconds: 0) }

    it { is_expected.to compile.and_raise_error(%r{http_timeout_seconds}) }
  end
end
