require 'spec_helper'

describe 'puppet_operational_dashboards::telegraf::agent' do
  let(:node) { 'localhost.foo.com' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'when using default parameters' do
        let(:pre_condition) do
          <<-PRE_COND
            function puppet_operational_dashboards::hosts_with_profile($profile) { return ['localhost.foo.com'] }
            class{ 'puppet_operational_dashboards':
              influxdb_host => 'localhost.foo.com',
              include_pe_metrics => true,
            }
          PRE_COND
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

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('telegraf').with(
            ensure: '1.29.4-1',
            archive_location: 'https://dl.influxdata.com/telegraf/releases/telegraf-1.29.4_linux_amd64.tar.gz',
            interval: '10m',
            manage_service: false,
            outputs: influxdb_v2,
          )

          is_expected.to contain_service('telegraf').with(ensure: 'running')
          is_expected.to contain_service('telegraf').that_requires(['Class[telegraf::install]', 'Exec[puppet_telegraf_daemon_reload]'])

          ['/etc/telegraf/puppet_ca.pem', '/etc/telegraf/puppet_cert.pem', '/etc/telegraf/puppet_key.pem', '/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem',
           '/etc/telegraf/key.pem'].each do |cert_file|
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
            %r{tls_cert = "/etc/telegraf/puppet_cert\.pem"},
          )
          is_expected.to contain_file('/etc/systemd/system/telegraf.service.d/override.conf').that_notifies(['Exec[puppet_telegraf_daemon_reload]', 'Service[telegraf]'])
        }
      end

      context 'when using postgres password auth' do
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
            use_system_store: false,
            manage_ssl: true,
            include_pe_metrics: true,
            telegraf_postgres_password: RSpec::Puppet::Sensitive.new('foo'),
            postgres_options: {
              'sslmode': 'verify-full',
              'sslkey': '/etc/telegraf/puppet_key.pem',
              'sslcert': '/etc/telegraf/puppet_cert.pem',
              'sslrootcert': '/etc/telegraf/puppet_ca.pem',
            },
            postgres_hosts: ['localhost.foo.com'],
          }
        end

        it {
          # rubocop:disable Layout/LineLength
          options = [{
            'address' => "postgres://telegraf:foo@localhost.foo.com:5432/pe-puppetdb?#{params[:postgres_options].map { |k, v| "#{k}=#{v}" }.join('&').chomp}",
            'databases' => ['pe-puppetdb'],
            'outputaddress' => 'localhost.foo.com',
            'query' => [
              { 'sqlquery' => 'SELECT * FROM pg_stat_database',
               'version' => 901,
               'withdbname' => false },
              { 'tagvalue' => 'table_name',
               'version' => 901,
               'withdbname' => false,
               'sqlquery' => "SELECT current_database() AS datname, total_bytes AS total , table_name , index_bytes AS index , toast_bytes AS toast , table_bytes AS table FROM ( SELECT *, total_bytes-index_bytes-coalesce(toast_bytes,0) AS table_bytes FROM ( SELECT c.oid,nspname AS table_schema, relname AS table_name , c.reltuples AS row_estimate , pg_total_relation_size(c.oid) AS total_bytes , pg_indexes_size(c.oid) AS index_bytes , pg_total_relation_size(reltoastrelid) AS toast_bytes FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE relkind = 'r' AND nspname NOT IN ('pg_catalog', 'information_schema')) a) a" },
              { 'sqlquery' => 'SELECT current_database() AS datname, relname as table, autovacuum_count, vacuum_count, n_live_tup, n_dead_tup FROM pg_stat_user_tables',
               'tagvalue' => 'table',
               'version' => 901,
               'withdbname' => false },
              { 'sqlquery' => 'SELECT current_database() AS datname, a.indexrelname as index, pg_relation_size(a.indexrelid) as size_bytes, idx_scan, idx_tup_read, idx_tup_fetch, idx_blks_read, idx_blks_hit from pg_stat_user_indexes a join pg_statio_user_indexes b on a.indexrelid = b.indexrelid;',
               'tagvalue' => 'index',
               'version' => 901,
               'withdbname' => false },
              { 'sqlquery' => 'SELECT current_database() AS datname, relname as table, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, tidx_blks_hit FROM pg_statio_user_tables', 'tagvalue' => 'table',
               'version' => 901,
               'withdbname' => false },
            ]
          }]
          # rubocop:enable Layout/LineLength

          is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
            options: options,
          )
        }
      end

      context 'when customizing the postgres connection string' do
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
            use_system_store: false,
            manage_ssl: true,
            include_pe_metrics: true,
            postgres_options: {
              'sslmode': 'verify-ca',
              'sslrootcert': '/tmp/foo',
            },
            postgres_hosts: ['localhost.foo.com'],
          }
        end

        it {
          # rubocop:disable Layout/LineLength
          options = [{
            'address' => "postgres://telegraf@localhost.foo.com:5432/pe-puppetdb?#{params[:postgres_options].map { |k, v| "#{k}=#{v}" }.join('&').chomp}",
            'databases' => ['pe-puppetdb'],
            'outputaddress' => 'localhost.foo.com',
            'query' => [
              { 'sqlquery' => 'SELECT * FROM pg_stat_database',
               'version' => 901,
               'withdbname' => false },
              { 'tagvalue' => 'table_name',
               'version' => 901,
               'withdbname' => false,
               'sqlquery' => "SELECT current_database() AS datname, total_bytes AS total , table_name , index_bytes AS index , toast_bytes AS toast , table_bytes AS table FROM ( SELECT *, total_bytes-index_bytes-coalesce(toast_bytes,0) AS table_bytes FROM ( SELECT c.oid,nspname AS table_schema, relname AS table_name , c.reltuples AS row_estimate , pg_total_relation_size(c.oid) AS total_bytes , pg_indexes_size(c.oid) AS index_bytes , pg_total_relation_size(reltoastrelid) AS toast_bytes FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE relkind = 'r' AND nspname NOT IN ('pg_catalog', 'information_schema')) a) a" },
              { 'sqlquery' => 'SELECT current_database() AS datname, relname as table, autovacuum_count, vacuum_count, n_live_tup, n_dead_tup FROM pg_stat_user_tables',
               'tagvalue' => 'table',
               'version' => 901,
               'withdbname' => false },
              { 'sqlquery' => 'SELECT current_database() AS datname, a.indexrelname as index, pg_relation_size(a.indexrelid) as size_bytes, idx_scan, idx_tup_read, idx_tup_fetch, idx_blks_read, idx_blks_hit from pg_stat_user_indexes a join pg_statio_user_indexes b on a.indexrelid = b.indexrelid;',
               'tagvalue' => 'index',
               'version' => 901,
               'withdbname' => false },
              { 'sqlquery' => 'SELECT current_database() AS datname, relname as table, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, tidx_blks_hit FROM pg_statio_user_tables', 'tagvalue' => 'table',
               'version' => 901,
               'withdbname' => false },
            ]
          }]
          # rubocop:enable Layout/LineLength

          is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
            options: options,
          )
        }
      end
      context 'when installing from archive on EL' do
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
            use_system_store: false,
            manage_repo: false,
            manage_archive: true,
            include_pe_metrics: true,
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
              use_system_store => false,
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

          ['/etc/telegraf/puppet_ca.pem', '/etc/telegraf/puppet_cert.pem', '/etc/telegraf/puppet_key.pem', '/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem',
           '/etc/telegraf/key.pem'].each do |cert_file|
             is_expected.not_to contain_file(cert_file)
           end

          is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
            %r{urls = \["http://localhost.foo.com:8140/status/v1/services\?level=debug"},
          )
          is_expected.not_to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
            %r{tls_cert = "/etc/telegraf/puppet_cert\.pem"},
          )
        }
      end

      context 'when using but not managing ssl' do
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
            use_system_store: false,
            manage_ssl: false,
            include_pe_metrics: true,
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

          ['/etc/telegraf/puppet_ca.pem', '/etc/telegraf/puppet_cert.pem', '/etc/telegraf/puppet_key.pem', '/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem',
           '/etc/telegraf/key.pem'].each do |cert_file|
             is_expected.not_to contain_file(cert_file)
           end
        }
      end

      context 'when customizing the collection interval' do
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
            use_system_store: false,
            collection_interval: '10s',
            include_pe_metrics: true,
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
            use_system_store: false,
            collection_method: 'local',
            include_pe_metrics: true,
          }
        end

        it {
          is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
        }
      end

      context 'when installed on OSP' do
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
            use_system_store: false,
            puppetserver_hosts: ['localhost.foo.com'],
            include_pe_metrics: false,
          }
        end

        it {
          is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
        }
      end

      context 'when collecting local services on OSP' do
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
            use_system_store: false,
            collection_method: 'local',
            local_services: ['puppetserver'],
            include_pe_metrics: false,
          }
        end

        it {
          is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com'])
        }
      end
      context 'when collecting local PE metrics' do
        let :params do
          {
            collection_method: 'local',
            token: RSpec::Puppet::Sensitive.new(nil),
            token_name: 'puppet telegraf token',
            influxdb_token_file: '/root/.influxdb_token',
            influxdb_host: 'localhost.foo.com',
            influxdb_port: 8086,
            influxdb_bucket: 'puppet_data',
            influxdb_org: 'puppetlabs',
            use_ssl: true,
            use_system_store: false,
            manage_repo: false,
            manage_archive: false,
            http_timeout_seconds: 120,
            version: '1.26.0',
            include_pe_metrics: true,
            profiles: ['Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Puppetdb', 'Puppet_enterprise::Profile::Orchestrator', 'Puppet_enterprise::Profile::Database'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_telegraf__processor('pcp_renames') }
        it { is_expected.to contain_telegraf__processor('orchestrator_renames') }
        it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('pcp') }
        it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('orchestrator') }
        it { is_expected.to contain_telegraf__input('pcp_metrics') }
        it { is_expected.to contain_telegraf__input('orchestrator_metrics') }
      end
    end
  end
end
