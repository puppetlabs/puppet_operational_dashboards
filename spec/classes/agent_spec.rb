require 'spec_helper'

describe 'puppet_operational_dashboards::telegraf::agent' do
  let(:facts) { { os: { family: 'RedHat' }, fqdn: 'localhost.foo.com' } }
  let(:node) { 'localhost.foo.com' }

  # Mock the hosts_with_profile() function and include the main class
  let(:pre_condition) do
    <<-PRE_COND
      function puppet_operational_dashboards::hosts_with_profile($profile) { return ['localhost.foo.com'] }
      class{ 'puppet_operational_dashboards':
        influxdb_host => 'localhost.foo.com',
        include_pe_metrics => true,
      }
    PRE_COND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end

  context 'when using default parameters' do
    let(:influxdb_v2) do
      {
        'influxdb_v2' => [
          {
            'tls_ca'               => '/etc/telegraf/ca.pem',
            'tls_cert'             => '/etc/telegraf/cert.pem',
            'insecure_skip_verify' => true,
            'bucket'               => 'puppet_data',
            'organization'         => 'puppetlabs',
            'token'                => '$INFLUX_TOKEN',
            'urls'                 => ['https://localhost.foo.com:8086']
          },
        ],
      }
    end

    it {
      is_expected.to contain_class('telegraf').with(
        ensure: '1.24.3-1',
        archive_location: 'https://dl.influxdata.com/telegraf/releases/telegraf-1.24.3_linux_amd64.tar.gz',
        interval: '10m',
        manage_service: false,
        outputs: influxdb_v2,
      )

      is_expected.to contain_service('telegraf').with(ensure: 'running')
      is_expected.to contain_service('telegraf').that_requires(['Class[telegraf::install]', 'Exec[puppet_telegraf_daemon_reload]'])

      ['/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem', '/etc/telegraf/key.pem'].each do |cert_file|
        is_expected.to contain_file(cert_file)
      end

      ['puppetdb', 'puppetdb_jvm', 'puppetserver'].each do |service|
        is_expected.to contain_puppet_operational_dashboards__telegraf__config(service)
      end

      ['puppetdb_jvm_renames', 'puppetdb_mbean_renames', 'puppetdb_renames', 'puppetserver_renames'].each do |rename|
        is_expected.to contain_telegraf__processor(rename)
      end

      ['postgres_localhost.foo.com', 'puppetdb_jvm_metrics', 'puppetdb_metrics', 'puppetserver_metrics'].each do |input|
        is_expected.to contain_telegraf__input(input)
      end

      is_expected.to contain_exec('puppet_telegraf_daemon_reload').with(refreshonly: true)

      is_expected.to contain_file('/etc/systemd/system/telegraf.service.d').that_requires('Class[telegraf::install]')

      is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
        %r{urls = \["https://localhost.foo.com:8140/status/v1/services\?level=debug"},
      )
      is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
        %r{tls_cert = "/etc/telegraf/cert\.pem"},
      )
      is_expected.to contain_file('/etc/systemd/system/telegraf.service.d/override.conf').that_notifies(['Exec[puppet_telegraf_daemon_reload]', 'Service[telegraf]'])
    }
  end

  context 'when installing from archive on EL' do
    let(:pre_condition) { '' }
    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        manage_repo: false,
        manage_archive: true,
      }
    end

    it {
      is_expected.to compile
      is_expected.not_to contain_yumrepo('influxdata')
    }
  end

  context 'when not using ssl' do
    let(:pre_condition) do
      <<-PRE_COND
        function puppet_operational_dashboards::hosts_with_profile($profile) { return ['localhost.foo.com'] }
        class{ 'puppet_operational_dashboards':
          influxdb_host => 'localhost.foo.com',
          use_ssl       => false,
          include_pe_metrics => true,
        }
      PRE_COND
    end

    let(:influxdb_v2) do
      {
        'influxdb_v2' => [
          {
            'bucket'               => 'puppet_data',
            'organization'         => 'puppetlabs',
            'token'                => '$INFLUX_TOKEN',
            'urls'                 => ['http://localhost.foo.com:8086']
          },
        ],
      }
    end

    it {
      is_expected.to contain_class('telegraf').with(outputs: influxdb_v2)

      ['/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem', '/etc/telegraf/key.pem'].each do |cert_file|
        is_expected.not_to contain_file(cert_file)
      end

      is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
        %r{urls = \["http://localhost.foo.com:8140/status/v1/services\?level=debug"},
      )
      is_expected.not_to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
        %r{tls_cert = "/etc/telegraf/cert\.pem"},
      )
    }
  end

  context 'when using but not managing ssl' do
    let(:pre_condition) { '' }
    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        manage_ssl: false,
      }
    end

    let(:influxdb_v2) do
      {
        'influxdb_v2' => [
          {
            'tls_ca'               => '/etc/telegraf/ca.pem',
            'tls_cert'             => '/etc/telegraf/cert.pem',
            'insecure_skip_verify' => true,
            'bucket'               => 'puppet_data',
            'organization'         => 'puppetlabs',
            'token'                => '$INFLUX_TOKEN',
            'urls'                 => ['https://localhost.foo.com:8086']
          },
        ],
      }
    end

    it {
      is_expected.to contain_class('telegraf').with(outputs: influxdb_v2)

      ['/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem', '/etc/telegraf/key.pem'].each do |cert_file|
        is_expected.not_to contain_file(cert_file)
      end
    }
  end

  context 'when customizing the collection interval' do
    let(:pre_condition) { '' }
    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        collection_interval: '10s',
      }
    end

    it {
      is_expected.to contain_file('/etc/telegraf/telegraf.conf').with_content(
        %r{interval = "10s"},
      )
    }
  end

  context 'when collecting local services on PE' do
    let(:pre_condition) do
      <<-PRE_COND
        function puppet_operational_dashboards::pe_profiles_on_host() { return ['Puppet_enterprise::Profile::Master'] }
      PRE_COND
    end

    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        collection_method: 'local',
      }
    end

    it {
      is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
    }
  end

  context 'when installed on OSP' do
    let(:pre_condition) { '' }
    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        puppetserver_hosts: ['localhost.foo.com'],
      }
    end

    it {
      is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
    }
  end

  context 'when collecting local services on OSP' do
    let(:pre_condition) { '' }
    let(:params) do
      {
        token: RSpec::Puppet::Sensitive.new(nil),
        token_name: 'puppet telegraf token',
        influxdb_token_file: '/root/.influxdb_token',
        influxdb_host: 'localhost.foo.com',
        influxdb_port: 8086,
        influxdb_bucket: 'puppet_data',
        influxdb_org: 'puppetlabs',
        use_ssl: true,
        collection_method: 'local',
        local_services: ['puppetserver'],
      }
    end

    it {
      is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
    }
  end
end
