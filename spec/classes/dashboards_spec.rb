# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::profile::dashboards' do
  let(:core_dashboards) { ['Puppetserver Performance', 'Puppetdb Performance', 'Postgresql Performance'] }
  let(:pe_dashboards) { ['Filesync Performance', 'Orchestrator Performance'] }
  let(:datasource_file) { '/etc/grafana/provisioning/datasources/influxdb.yaml' }

  # Parameters that default to values from the base class, used when declaring this class directly
  let(:base_params) do
    {
      use_ssl: true,
      use_system_store: false,
      influxdb_host: 'localhost',
      influxdb_port: 8086,
      influxdb_bucket: 'puppet_data',
      telegraf_token_name: 'puppet telegraf token',
      influxdb_token_file: '/root/.influxdb_token',
      include_pe_metrics: true,
      manage_system_board: true,
    }
  end

  let(:pre_condition) do
    <<-PRE_COND
      class { 'puppet_operational_dashboards':
        include_pe_metrics  => true,
        manage_system_board => true,
      }
    PRE_COND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      case os_facts[:os]['family']
      when 'RedHat', 'Debian'
        it { is_expected.to contain_class('grafana').with(install_method: 'repo') }
      else
        it { is_expected.to contain_class('grafana').with(install_method: 'package') }
      end
    end
  end

  context 'with default facts' do
    let(:facts) { on_supported_os['redhat-9-x86_64'] }

    context 'when using default parameters' do
      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('grafana').with(
          install_method: 'repo',
          version: '11.6.8',
          manage_package_repo: true,
          cfg: {},
        )
      }

      it { is_expected.to contain_service('grafana').with_ensure('running') }

      it {
        is_expected.to contain_file('grafana-conf-d').with(
          ensure: 'directory',
          path: '/etc/systemd/system/grafana-server.service.d',
        )
      }

      it {
        is_expected.to contain_file('wait-for-grafana').with(
          ensure: 'file',
          path: '/etc/systemd/system/grafana-server.service.d/wait.conf',
        ).with_content(
          %r{ExecStartPost=/usr/bin/timeout 10 sh -c 'while ! ss -t -l -n sport = :3000 \| sed 1d \| grep -q "\^LISTEN\.\*:3000"; do sleep 1; done'},
        )
        is_expected.to contain_file('wait-for-grafana').that_subscribes_to('Exec[puppet_grafana_daemon_reload]')
      }

      it {
        is_expected.to contain_exec('puppet_grafana_daemon_reload').with(
          command: 'systemctl daemon-reload',
          refreshonly: true,
        ).that_notifies('Service[grafana-server]')
      }

      it 'manages every dashboard against the local Grafana' do
        (core_dashboards + pe_dashboards + ['System_v2 Performance']).each do |dashboard|
          is_expected.to contain_grafana_dashboard(dashboard).with(
            grafana_user: 'admin',
            grafana_password: 'admin',
            grafana_url: 'http://foo.bar.com:3000',
          ).that_requires('Class[grafana::install]')
        end
      end

      it 'loads the dashboard content from the module files' do
        (core_dashboards + pe_dashboards + ['System_v2 Performance']).each do |dashboard|
          source = File.join(__dir__, '..', '..', 'files', "#{dashboard.sub(' Performance', '')}_performance.json")
          is_expected.to contain_grafana_dashboard(dashboard).with_content(File.read(source))
        end
      end

      it { is_expected.not_to contain_grafana_dashboard('System Performance') }
      it { is_expected.not_to contain_file('grafana_provisioning_datasource') }

      it {
        is_expected.to contain_file(datasource_file).with(
          ensure: 'file',
          mode: '0600',
          owner: 'grafana',
        ).that_requires('Class[grafana::install]').that_notifies('Service[grafana-server]')
      }

      it 'renders the datasource with a Deferred token lookup when no token is given' do
        expect(catalogue.resource('File', datasource_file).sensitive_parameters).to include(:content)
        name, args = deferred_call(deferred_param("File[#{datasource_file}]", :content))
        expect(name).to eq('inline_epp')
        expect(args[0]).to eq(File.read(File.join(__dir__, '..', '..', 'files', 'datasource.epp')))

        vars = args[1]
        expect(vars).to include('name' => 'influxdb_puppet', 'database' => 'puppet_data', 'url' => 'https://foo.bar.com:8086')
        expect(deferred_call(vars['token'])).to eq(
          ['influxdb::retrieve_token', ['https://foo.bar.com:8086', 'puppet telegraf token', '/root/.influxdb_token', false]],
        )
      end
    end

    context 'when not managing grafana' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), manage_grafana: false) }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.not_to contain_class('grafana')
        is_expected.not_to contain_file('wait-for-grafana')
        is_expected.not_to contain_file('grafana-conf-d')
        is_expected.not_to contain_exec('puppet_grafana_daemon_reload')
        is_expected.not_to contain_file('grafana_provisioning_datasource')
        is_expected.not_to contain_file(datasource_file)
      }

      it 'still manages the dashboards, without requiring the grafana install class' do
        (core_dashboards + pe_dashboards).each do |dashboard|
          is_expected.to contain_grafana_dashboard(dashboard)
          is_expected.not_to contain_grafana_dashboard(dashboard).that_requires('Class[grafana::install]')
        end
      end
    end

    context 'when passing a token' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo')) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_file(datasource_file) }

      it {
        is_expected.to contain_file('grafana_provisioning_datasource').with(
          ensure: 'file',
          path: datasource_file,
          mode: '0600',
          owner: 'grafana',
        ).that_requires('Class[grafana::install]').that_notifies('Service[grafana-server]')
      }

      it 'renders the token into the datasource and keeps the content sensitive' do
        resource = catalogue.resource('File', 'grafana_provisioning_datasource')
        expect(resource.sensitive_parameters).to include(:content)
        expect(resource[:content]).to include("httpHeaderValue1: 'Token foo'")
        expect(resource[:content]).to include('url: https://localhost:8086')
        expect(resource[:content]).to include('database: puppet_data')
        expect(resource[:content]).to include('- name: influxdb_puppet')
      end
    end

    context 'when querying InfluxDB without ssl' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), use_ssl: false, grafana_datasource: 'custom_ds') }

      it {
        content = catalogue.resource('File', 'grafana_provisioning_datasource')[:content]
        expect(content).to include('url: http://localhost:8086')
        expect(content).to include('- name: custom_ds')
      }
    end

    context 'when using the system CA store for the Deferred token lookup' do
      let(:pre_condition) do
        <<-PRE_COND
          class { 'puppet_operational_dashboards':
            use_system_store   => true,
            include_pe_metrics => true,
          }
        PRE_COND
      end

      it {
        catalogue
        _name, args = deferred_call(deferred_param("File[#{datasource_file}]", :content))
        expect(deferred_call(args[1]['token'])).to eq(
          ['influxdb::retrieve_token', ['https://foo.bar.com:8086', 'puppet telegraf token', '/root/.influxdb_token', true]],
        )
      }
    end

    context 'when managing system dashboards' do
      it { is_expected.to contain_grafana_dashboard('System_v2 Performance').with_ensure('present') }
      it { is_expected.not_to contain_grafana_dashboard('System Performance') }
    end

    context 'when managing the v1 system dashboard' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), system_dashboard_version: 'v1') }

      it { is_expected.to contain_grafana_dashboard('System Performance').with_ensure('present') }
      it { is_expected.not_to contain_grafana_dashboard('System_v2 Performance') }
    end

    context 'when managing all system dashboards' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), system_dashboard_version: 'all') }

      it { is_expected.to contain_grafana_dashboard('System Performance').with_ensure('present') }
      it { is_expected.to contain_grafana_dashboard('System_v2 Performance').with_ensure('present') }
    end

    context 'when not managing system dashboards' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), manage_system_board: false) }

      it 'removes both versions of the system dashboard' do
        ['System Performance', 'System_v2 Performance'].each do |dashboard|
          is_expected.to contain_grafana_dashboard(dashboard).with(ensure: 'absent', content: '{}')
        end
      end
    end

    context 'when not including PE metrics' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), include_pe_metrics: false) }

      it 'removes the PE only dashboards' do
        pe_dashboards.each do |dashboard|
          is_expected.to contain_grafana_dashboard(dashboard).with_ensure('absent')
        end
      end

      it 'still manages the core dashboards' do
        core_dashboards.each do |dashboard|
          is_expected.to contain_grafana_dashboard(dashboard).without_ensure
        end
      end
    end

    context 'when customizing grafana' do
      let(:pre_condition) { '' }
      let(:params) do
        base_params.merge(
          token: sensitive('foo'),
          grafana_host: 'grafana.example.com',
          grafana_port: 8443,
          grafana_timeout: 60,
          grafana_password: sensitive('secret'),
          grafana_version: '12.0.0',
          grafana_install: 'package',
          manage_grafana_repo: false,
        )
      end

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('grafana').with(
          install_method: 'package',
          version: '12.0.0',
          manage_package_repo: false,
        )
      }

      it {
        is_expected.to contain_file('wait-for-grafana').with_content(
          %r{timeout 60 sh -c 'while ! ss -t -l -n sport = :8443 \| sed 1d \| grep -q "\^LISTEN\.\*:8443"},
        )
      }

      it {
        is_expected.to contain_grafana_dashboard('Puppetserver Performance').with(
          grafana_url: 'http://grafana.example.com:8443',
          grafana_password: 'secret',
        )
      }
    end

    context 'when using and managing ssl' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), manage_system_board: false, manage_grafana: true, grafana_use_ssl: true) }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file('/etc/grafana/client.pem').with(
          ensure: 'file',
          source: "file:////etc/puppetlabs/puppet/ssl/certs/#{catalogue.name}.pem",
        ).that_notifies('Service[grafana-server]')
        is_expected.to contain_file('/etc/grafana/client.key').with(
          ensure: 'file',
          source: "file:////etc/puppetlabs/puppet/ssl/private_keys/#{catalogue.name}.pem",
        ).that_notifies('Service[grafana-server]')
      }

      it {
        is_expected.to contain_class('grafana').with(
          cfg: { 'server' => { 'protocol' => 'https', 'cert_file' => '/etc/grafana/client.pem', 'cert_key' => '/etc/grafana/client.key' } },
        )
      }

      it { is_expected.to contain_grafana_dashboard('Puppetserver Performance').with_grafana_url(%r{^https://}) }
    end

    context 'when using ssl with custom certificate locations' do
      let(:pre_condition) { '' }
      let(:params) do
        base_params.merge(
          token: sensitive('foo'),
          grafana_use_ssl: true,
          grafana_cert_file: '/etc/grafana/custom.pem',
          grafana_key_file: '/etc/grafana/custom.key',
          grafana_cert_file_source: '/tmp/cert.pem',
          grafana_key_file_source: '/tmp/key.pem',
        )
      end

      it { is_expected.to contain_file('/etc/grafana/custom.pem').with_source('file:////tmp/cert.pem') }
      it { is_expected.to contain_file('/etc/grafana/custom.key').with_source('file:////tmp/key.pem') }

      it {
        is_expected.to contain_class('grafana').with(
          cfg: { 'server' => { 'protocol' => 'https', 'cert_file' => '/etc/grafana/custom.pem', 'cert_key' => '/etc/grafana/custom.key' } },
        )
      }
    end

    context 'when using and not managing ssl' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), manage_system_board: false, manage_grafana: true, manage_grafana_ssl: false, grafana_use_ssl: true) }

      it {
        is_expected.not_to contain_file('/etc/grafana/client.pem')
        is_expected.not_to contain_file('/etc/grafana/client.key')
      }

      it {
        is_expected.to contain_class('grafana').with(
          cfg: { 'server' => { 'protocol' => 'https', 'cert_file' => '/etc/grafana/client.pem', 'cert_key' => '/etc/grafana/client.key' } },
        )
      }

      it { is_expected.to contain_grafana_dashboard('Puppetserver Performance').with_grafana_url(%r{^https://}) }
    end

    context 'when not using ssl' do
      let(:pre_condition) { '' }
      let(:params) { base_params.merge(token: sensitive('foo'), manage_system_board: false, manage_grafana: true, grafana_use_ssl: false) }

      it {
        is_expected.not_to contain_file('/etc/grafana/client.pem')
        is_expected.not_to contain_file('/etc/grafana/client.key')
      }

      it { is_expected.to contain_class('grafana').with(cfg: {}) }
      it { is_expected.to contain_grafana_dashboard('Puppetserver Performance').with_grafana_url(%r{^http://}) }
    end
  end
end
