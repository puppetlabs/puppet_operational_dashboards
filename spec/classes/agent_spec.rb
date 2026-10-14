# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::telegraf::agent' do
  let(:node) { 'localhost.foo.com' }
  let(:override_conf) { '/etc/systemd/system/telegraf.service.d/override.conf' }
  let(:cert_files) do
    ['/etc/telegraf/puppet_ca.pem', '/etc/telegraf/puppet_cert.pem', '/etc/telegraf/puppet_key.pem', '/etc/telegraf/ca.pem', '/etc/telegraf/cert.pem', '/etc/telegraf/key.pem']
  end

  # Parameters that default to values from the base class, used when declaring this class directly
  let(:base_params) do
    {
      token: sensitive('telegraf_token'),
      token_name: 'puppet telegraf token',
      influxdb_token_file: '/root/.influxdb_token',
      influxdb_host: 'localhost.foo.com',
      influxdb_port: 8086,
      influxdb_bucket: 'puppet_data',
      influxdb_org: 'puppetlabs',
      use_ssl: true,
      use_system_store: false,
      include_pe_metrics: true,
      template_format: 'toml',
    }
  end

  let(:default_pg_params) { 'sslmode=verify-full&sslkey=/etc/telegraf/puppet_key.pem&sslcert=/etc/telegraf/puppet_cert.pem&sslrootcert=/etc/telegraf/puppet_ca.pem' }

  # The options rendered by the postgres.{toml,yaml}.epp templates, which must be identical
  def postgres_options(address, database = 'pe-puppetdb', outputaddress = 'localhost.foo.com')
    # rubocop:disable Layout/LineLength
    [{
      'address' => address,
      'databases' => ['pe-puppetdb'],
      'outputaddress' => outputaddress,
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
        { 'sqlquery' => 'SELECT current_database() AS datname, relname as table, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, tidx_blks_hit FROM pg_statio_user_tables',
          'tagvalue' => 'table',
          'version' => 901,
          'withdbname' => false },
      ]
    }].tap { |opts| opts.first['address'] = address.sub('/pe-puppetdb?', "/#{database}?") }
    # rubocop:enable Layout/LineLength
  end

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
        # Telegraf is installed from a repo on RedHat and Debian, and from an archive elsewhere
        let(:manage_repo) { ['RedHat', 'Debian'].include?(os_facts[:os]['family']) }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('telegraf').with(
            ensure: '1.29.4-1',
            manage_repo: manage_repo,
            manage_archive: !manage_repo,
            manage_user: true,
            archive_location: 'https://dl.influxdata.com/telegraf/releases/telegraf-1.29.4_linux_amd64.tar.gz',
            archive_install_dir: '/opt/telegraf',
            interval: '10m',
            hostname: '',
            manage_service: false,
            outputs: influxdb_v2,
          ).that_notifies('Service[telegraf]')
        }

        it {
          is_expected.to contain_service('telegraf').with(ensure: 'running')
          is_expected.to contain_service('telegraf').that_requires(['Class[telegraf::install]', 'Exec[puppet_telegraf_daemon_reload]'])
        }

        it {
          cert_files.each do |cert_file|
            is_expected.to contain_file(cert_file).with(
              ensure: 'file',
              mode: '0400',
              owner: 'telegraf',
            ).that_requires('Class[telegraf::install]').that_notifies('Service[telegraf]')
          end
        }

        it 'copies the puppet agent certificates for telegraf' do
          {
            '/etc/telegraf/cert.pem' => '/etc/puppetlabs/puppet/ssl/certs/localhost.foo.com.pem',
            '/etc/telegraf/puppet_cert.pem' => '/etc/puppetlabs/puppet/ssl/certs/localhost.foo.com.pem',
            '/etc/telegraf/key.pem' => '/etc/puppetlabs/puppet/ssl/private_keys/localhost.foo.com.pem',
            '/etc/telegraf/puppet_key.pem' => '/etc/puppetlabs/puppet/ssl/private_keys/localhost.foo.com.pem',
            '/etc/telegraf/ca.pem' => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
            '/etc/telegraf/puppet_ca.pem' => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
          }.each do |file, source|
            is_expected.to contain_file(file).with_source("file:///#{source}")
          end
        end

        it {
          ['puppetdb', 'puppetdb_jvm', 'puppetserver', 'orchestrator', 'pcp'].each do |service|
            is_expected.to contain_puppet_operational_dashboards__telegraf__config(service).with(
              protocol: 'https',
              http_timeout_seconds: 5,
              template_format: 'toml',
            ).that_requires("File[#{override_conf}]")
          end
        }

        it {
          ['puppetdb_jvm_renames', 'puppetdb_mbean_renames', 'puppetdb_renames', 'puppetserver_renames', 'orchestrator_renames', 'pcp_renames'].each do |rename|
            is_expected.to contain_telegraf__processor(rename)
          end
        }

        it {
          ['postgres_localhost.foo.com', 'puppetdb_jvm_metrics', 'puppetdb_metrics', 'puppetserver_metrics', 'orchestrator_metrics', 'pcp_metrics'].each do |input|
            is_expected.to contain_telegraf__input(input).that_notifies('Service[telegraf]')
          end
        }

        it { is_expected.to contain_exec('puppet_telegraf_daemon_reload').with(command: 'systemctl daemon-reload', refreshonly: true) }

        it {
          is_expected.to contain_file('/etc/systemd/system/telegraf.service.d').with(
            ensure: 'directory',
            owner: 'telegraf',
            group: 'telegraf',
            mode: '0700',
          ).that_requires('Class[telegraf::install]')
        }

        it {
          is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
            %r{urls = \["https://localhost.foo.com:8140/status/v1/services\?level=debug"},
          )
          is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
            %r{tls_cert = "/etc/telegraf/puppet_cert\.pem"},
          )
        }

        it { is_expected.to contain_file(override_conf).that_notifies(['Exec[puppet_telegraf_daemon_reload]', 'Service[telegraf]']) }

        it 'retrieves the telegraf token with a Deferred function call' do
          expect(catalogue.resource('File', override_conf).sensitive_parameters).to include(:content)

          name, args = deferred_call(deferred_param("File[#{override_conf}]", :content))
          expect(name).to eq('inline_epp')
          expect(args[0]).to match(%r{Environment="INFLUX_TOKEN=<%= \$token %>"})
          expect(deferred_call(args[1]['token'])).to eq(
            ['influxdb::retrieve_token', ['https://localhost.foo.com:8086', 'puppet telegraf token', '/root/.influxdb_token', false]],
          )
        end
      end
    end
  end

  context 'with default facts' do
    let(:facts) { on_supported_os['redhat-9-x86_64'] }

    context 'when passing a token' do
      let(:params) { base_params.merge(postgres_hosts: ['localhost.foo.com']) }

      it { is_expected.to compile.with_all_deps }

      it 'renders the token into the systemd override and keeps it sensitive' do
        resource = catalogue.resource('File', override_conf)
        expect(resource.sensitive_parameters).to include(:content)
        expect(resource[:content]).to eq("[Service]\nEnvironment=\"INFLUX_TOKEN=telegraf_token\"\n")
      end
    end

    context 'when using postgres password auth' do
      let(:params) do
        base_params.merge(
          manage_ssl: true,
          telegraf_postgres_password: sensitive('foo'),
          postgres_hosts: ['localhost.foo.com'],
        )
      end

      it {
        is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
          plugin_type: 'postgresql_extensible',
          options: postgres_options("postgres://telegraf:foo@localhost.foo.com:5432/pe-puppetdb?#{default_pg_params}"),
        )
      }
    end

    context 'when customizing the postgres connection string' do
      let(:params) do
        base_params.merge(
          postgres_options: { 'sslmode' => 'verify-ca', 'sslrootcert' => '/tmp/foo' },
          postgres_port: 5433,
          telegraf_user: 'metrics',
          postgres_hosts: ['localhost.foo.com'],
        )
      end

      it {
        is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
          options: postgres_options('postgres://metrics@localhost.foo.com:5433/pe-puppetdb?sslmode=verify-ca&sslrootcert=/tmp/foo'),
        )
      }
    end

    context 'when collecting postgres metrics from multiple hosts' do
      let(:params) { base_params.merge(postgres_hosts: ['pg2.foo.com', 'pg1.foo.com']) }

      it 'creates one input per host' do
        ['pg1.foo.com', 'pg2.foo.com'].each do |host|
          is_expected.to contain_telegraf__input("postgres_#{host}").with(
            options: postgres_options("postgres://telegraf@#{host}:5432/pe-puppetdb?#{default_pg_params}", 'pe-puppetdb', host),
          )
        end
      end
    end

    context 'when collecting postgres metrics on OSP' do
      let(:params) { base_params.merge(include_pe_metrics: false, postgres_hosts: ['localhost.foo.com']) }

      it {
        is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
          options: postgres_options("postgres://telegraf@localhost.foo.com:5432/puppetdb?#{default_pg_params}", 'puppetdb'),
        )
      }
    end

    ['toml', 'yaml'].each do |format|
      context "when rendering postgres configuration with the #{format} template format" do
        let(:params) do
          base_params.merge(
            template_format: format,
            telegraf_postgres_password: sensitive('foo'),
            postgres_hosts: ['localhost.foo.com'],
          )
        end

        it 'renders identical options from both template formats' do
          is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
            options: postgres_options("postgres://telegraf:foo@localhost.foo.com:5432/pe-puppetdb?#{default_pg_params}"),
          )
        end
      end

      context "when collecting local postgres metrics with the #{format} template format" do
        let(:params) do
          base_params.merge(
            template_format: format,
            collection_method: 'local',
            local_services: ['postgres'],
          )
        end

        it {
          is_expected.to contain_telegraf__input('postgres_localhost.foo.com').with(
            options: postgres_options("postgres://telegraf@localhost.foo.com:5432/pe-puppetdb?#{default_pg_params}"),
          )
        }
      end
    end

    context 'when installing from archive on EL' do
      let(:params) { base_params.merge(manage_repo: false, manage_archive: true, puppetserver_hosts: ['localhost.foo.com']) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_yumrepo('influxdata') }
      it { is_expected.to contain_class('telegraf').with(manage_repo: false, manage_archive: true) }
    end

    context 'when installing a custom telegraf version' do
      let(:params) { base_params.merge(version: '1.30.1-1', manage_repo: false, archive_install_dir: '/usr/local/telegraf', puppetserver_hosts: ['localhost.foo.com']) }

      it {
        is_expected.to contain_class('telegraf').with(
          ensure: '1.30.1-1',
          manage_archive: true,
          archive_location: 'https://dl.influxdata.com/telegraf/releases/telegraf-1.30.1_linux_amd64.tar.gz',
          archive_install_dir: '/usr/local/telegraf',
        )
      }
    end

    context 'when installing from a custom archive location' do
      let(:params) { base_params.merge(archive_location: 'https://mirror.example.com/telegraf.tar.gz', manage_user: false, puppetserver_hosts: ['localhost.foo.com']) }

      it { is_expected.to contain_class('telegraf').with(archive_location: 'https://mirror.example.com/telegraf.tar.gz', manage_user: false) }
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

        cert_files.each do |cert_file|
          is_expected.not_to contain_file(cert_file)
        end

        is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
          %r{urls = \["http://localhost.foo.com:8140/status/v1/services\?level=debug"},
        )
        is_expected.not_to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(
          %r{tls_cert = "/etc/telegraf/puppet_cert\.pem"},
        )
      }

      it {
        ['puppetdb', 'puppetdb_jvm', 'puppetserver', 'orchestrator', 'pcp'].each do |service|
          is_expected.to contain_puppet_operational_dashboards__telegraf__config(service).with_protocol('http')
        end
      }

      it 'retrieves the telegraf token over http' do
        _name, args = deferred_call(deferred_param("File[#{override_conf}]", :content))
        expect(deferred_call(args[1]['token'])[1][0]).to eq('http://localhost.foo.com:8086')
      end
    end

    context 'when using but not managing ssl' do
      let(:params) { base_params.merge(manage_ssl: false, puppetserver_hosts: ['localhost.foo.com']) }

      it {
        is_expected.to contain_class('telegraf').with(
          outputs: {
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
          },
        )

        cert_files.each do |cert_file|
          is_expected.not_to contain_file(cert_file)
        end
      }
    end

    context 'when verifying the InfluxDB certificate with custom certificate files' do
      let(:params) do
        base_params.merge(
          insecure_skip_verify: false,
          ssl_cert_file: '/tmp/cert.pem',
          ssl_key_file: '/tmp/key.pem',
          ssl_ca_file: '/tmp/ca.pem',
          puppet_ssl_cert_file: '/tmp/puppet_cert.pem',
          puppet_ssl_key_file: '/tmp/puppet_key.pem',
          puppet_ssl_ca_file: '/tmp/puppet_ca.pem',
          puppetserver_hosts: ['localhost.foo.com'],
        )
      end

      it 'disables insecure_skip_verify' do
        outputs = catalogue.resource('Class', 'telegraf')[:outputs]
        expect(outputs['influxdb_v2'].first['insecure_skip_verify']).to be(false)
      end

      it {
        {
          '/etc/telegraf/cert.pem' => '/tmp/cert.pem',
          '/etc/telegraf/key.pem' => '/tmp/key.pem',
          '/etc/telegraf/ca.pem' => '/tmp/ca.pem',
          '/etc/telegraf/puppet_cert.pem' => '/tmp/puppet_cert.pem',
          '/etc/telegraf/puppet_key.pem' => '/tmp/puppet_key.pem',
          '/etc/telegraf/puppet_ca.pem' => '/tmp/puppet_ca.pem',
        }.each do |file, source|
          is_expected.to contain_file(file).with_source("file:///#{source}")
        end
      }
    end

    context 'when using the system CA store and a custom token name' do
      let(:params) do
        base_params.merge(
          token: :undef,
          use_system_store: true,
          token_name: 'custom token',
          influxdb_token_file: '/etc/influxdb_token',
          puppetserver_hosts: ['localhost.foo.com'],
        )
      end
      let(:pre_condition) do
        <<-PRE_COND
          class puppet_operational_dashboards {
            $telegraf_token = undef
          }
          include puppet_operational_dashboards
        PRE_COND
      end

      it 'passes the settings to the Deferred token lookup' do
        _name, args = deferred_call(deferred_param("File[#{override_conf}]", :content))
        expect(deferred_call(args[1]['token'])).to eq(
          ['influxdb::retrieve_token', ['https://localhost.foo.com:8086', 'custom token', '/etc/influxdb_token', true]],
        )
      end
    end

    context 'when customizing the collection interval and http timeout' do
      let(:params) { base_params.merge(collection_interval: '10s', http_timeout_seconds: 120, puppetserver_hosts: ['localhost.foo.com']) }

      it { is_expected.to contain_file('/etc/telegraf/telegraf.conf').with_content(%r{interval = "10s"}) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with_http_timeout_seconds(120) }
      it { is_expected.to contain_file('/etc/telegraf/telegraf.d/puppetserver_metrics.conf').with_content(%r{timeout = "120s"}) }
    end

    context 'when collecting from all hosts' do
      let(:params) do
        base_params.merge(
          puppetserver_hosts: ['compiler2.foo.com', 'primary.foo.com', 'compiler1.foo.com'],
          puppetdb_hosts: ['primary.foo.com', 'compiler1.foo.com'],
          orchestrator_hosts: ['primary.foo.com'],
          postgres_hosts: [],
        )
      end

      it { is_expected.to compile.with_all_deps }

      it 'sorts the hosts for each service' do
        is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with_hosts(['compiler1.foo.com', 'compiler2.foo.com', 'primary.foo.com'])
        is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb').with_hosts(['compiler1.foo.com', 'primary.foo.com'])
        is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb_jvm').with_hosts(['compiler1.foo.com', 'primary.foo.com'])
        is_expected.to contain_puppet_operational_dashboards__telegraf__config('orchestrator').with_hosts(['primary.foo.com'])
      end

      it 'queries pcp metrics on the orchestrator port when a server also runs orchestrator' do
        is_expected.to contain_puppet_operational_dashboards__telegraf__config('pcp').with_hosts(
          ['compiler1.foo.com:8140', 'compiler2.foo.com:8140', 'primary.foo.com:8143'],
        )
      end

      it { expect(catalogue.resources.select { |r| r.type == 'Telegraf::Input' }.map(&:title)).not_to include(a_string_starting_with('postgres_')) }
    end

    context 'when collecting from all hosts without PE metrics' do
      let(:params) { base_params.merge(include_pe_metrics: false, puppetserver_hosts: ['primary.foo.com'], orchestrator_hosts: ['primary.foo.com']) }

      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('pcp') }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('orchestrator') }
    end

    context 'when only some services have hosts' do
      let(:params) { base_params.merge(puppetdb_hosts: ['puppetdb.foo.com']) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb').with_hosts(['puppetdb.foo.com']) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb_jvm').with_hosts(['puppetdb.foo.com']) }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('puppetserver') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('orchestrator') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('pcp') }
    end

    # The 'No services detected' guard treats empty arrays as truthy, so it never fails. The provision_dashboard
    # plan relies on this, as it applies the class with no PuppetDB to discover hosts from.
    context 'when no services are found' do
      let(:params) { base_params }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('telegraf') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('puppetserver') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('puppetdb') }
    end

    context 'when not collecting any metrics' do
      let(:params) { base_params.merge(collection_method: 'none', puppetserver_hosts: ['localhost.foo.com'], postgres_hosts: ['localhost.foo.com']) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('telegraf') }
      it { is_expected.to contain_service('telegraf') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('puppetserver') }
      it { is_expected.not_to contain_telegraf__input('postgres_localhost.foo.com') }
    end

    context 'when using the yaml template format' do
      let(:params) { base_params.merge(template_format: 'yaml', puppetserver_hosts: ['localhost.foo.com'], puppetdb_hosts: ['localhost.foo.com']) }

      it { is_expected.to compile.with_all_deps }

      it {
        ['puppetserver', 'puppetdb', 'puppetdb_jvm'].each do |service|
          is_expected.to contain_puppet_operational_dashboards__telegraf__config(service).with_template_format('yaml')
        end
      }
    end

    context 'when collecting local services on PE' do
      let(:pre_condition) do
        <<-PRE_COND
          function puppet_operational_dashboards::pe_profiles_on_host() { return ['Puppet_enterprise::Profile::Master'] }
        PRE_COND
      end

      let(:params) { base_params.merge(collection_method: 'local') }

      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com']) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('pcp').with(hosts: ['localhost.foo.com:8140']) }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('puppetdb') }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('orchestrator') }
      it { is_expected.not_to contain_telegraf__input('postgres_localhost.foo.com') }
    end

    context 'when installed on OSP' do
      let(:params) { base_params.merge(puppetserver_hosts: ['localhost.foo.com'], include_pe_metrics: false) }

      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com']) }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('pcp') }
    end

    context 'when collecting local services on OSP' do
      let(:params) { base_params.merge(collection_method: 'local', local_services: ['puppetserver'], include_pe_metrics: false) }

      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com']) }
      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('pcp') }
    end

    context 'when collecting every local service on OSP' do
      let(:params) do
        base_params.merge(
          collection_method: 'local',
          local_services: ['puppetserver', 'puppetdb', 'orchestrator', 'postgres'],
          include_pe_metrics: false,
        )
      end

      it { is_expected.to compile.with_all_deps }

      it {
        ['puppetserver', 'puppetdb', 'puppetdb_jvm', 'orchestrator'].each do |service|
          is_expected.to contain_puppet_operational_dashboards__telegraf__config(service).with(hosts: ['localhost.foo.com'])
        end
      }

      it { is_expected.not_to contain_puppet_operational_dashboards__telegraf__config('pcp') }
      it { is_expected.to contain_telegraf__input('postgres_localhost.foo.com') }
    end

    context 'when collecting local PE metrics' do
      let :params do
        base_params.merge(
          collection_method: 'local',
          manage_repo: false,
          manage_archive: false,
          http_timeout_seconds: 120,
          version: '1.26.0',
          profiles: ['Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Puppetdb', 'Puppet_enterprise::Profile::Orchestrator', 'Puppet_enterprise::Profile::Database'],
        )
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('telegraf').with(ensure: '1.26.0', manage_repo: false, manage_archive: false) }
      it { is_expected.to contain_telegraf__processor('pcp_renames') }
      it { is_expected.to contain_telegraf__processor('orchestrator_renames') }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('pcp').with(hosts: ['localhost.foo.com:8143'], http_timeout_seconds: 120) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('orchestrator').with(hosts: ['localhost.foo.com']) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb').with(hosts: ['localhost.foo.com']) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetdb_jvm').with(hosts: ['localhost.foo.com']) }
      it { is_expected.to contain_puppet_operational_dashboards__telegraf__config('puppetserver').with(hosts: ['localhost.foo.com']) }
      it { is_expected.to contain_telegraf__input('pcp_metrics') }
      it { is_expected.to contain_telegraf__input('orchestrator_metrics') }
      it { is_expected.to contain_telegraf__input('postgres_localhost.foo.com') }

      it {
        is_expected.to contain_file('/etc/telegraf/telegraf.d/orchestrator_metrics.conf').with_content(
          %r{urls = \["https://localhost.foo.com:8143/status/v1/services\?level=debug"\]},
        )
      }
    end
  end
end
