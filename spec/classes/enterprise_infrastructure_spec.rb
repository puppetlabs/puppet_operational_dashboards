# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::enterprise_infrastructure' do
  # Stand-ins for PE only classes and defined types used by the postgres_access profile
  let(:pe_stubs) do
    <<-PRE_COND
      class pe_postgresql::server {}
      include pe_postgresql::server
      define pe_postgresql_psql($db, $port, $psql_user, $psql_group, $unless, $psql_path, $command = 'foo') {}
      define pe_postgresql::server::database_grant($privilege, $db, $role) {}
      define puppet_enterprise::pg::cert_allowlist_entry(
        $user, $database, $allowed_client_certname, $pg_ident_conf_path, $ip_mask_allow_all_users_ssl, $ipv6_mask_allow_all_users_ssl,
      ) {}
      # Notified by influxdb::profile::toml
      service { 'puppetserver': }
    PRE_COND
  end
  let(:pre_condition) { pe_stubs }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
    end
  end

  context 'with default facts' do
    let(:facts) { on_supported_os['redhat-9-x86_64'] }

    context 'when the node has no PE profiles' do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_class('influxdb::profile::toml') }
      it { is_expected.not_to contain_class('puppet_operational_dashboards::profile::postgres_access') }
    end

    context 'when the node is a primary server' do
      let(:params) { { profiles: ['Puppet_enterprise::Profile::Master'] } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('influxdb::profile::toml') }
      it { is_expected.to contain_package('toml-rb').with(provider: 'puppetserver_gem').that_notifies('Service[puppetserver]') }
      it { is_expected.not_to contain_class('puppet_operational_dashboards::profile::postgres_access') }
    end

    context 'when the node is a primary server using the yaml template format' do
      let(:params) { { profiles: ['Puppet_enterprise::Profile::Master'], template_format: 'yaml' } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_class('influxdb::profile::toml') }
    end

    context 'when the node is a database server' do
      let(:params) { { profiles: ['Puppet_enterprise::Profile::Database'] } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::postgres_access') }
      it { is_expected.not_to contain_class('influxdb::profile::toml') }
    end

    context 'when the node is a primary server with a database' do
      let(:params) { { profiles: ['Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Database', 'Puppet_enterprise::Profile::Puppetdb'] } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('influxdb::profile::toml') }
      it { is_expected.to contain_class('puppet_operational_dashboards::profile::postgres_access') }
    end

    context 'when the node only runs PuppetDB' do
      let(:params) { { profiles: ['Puppet_enterprise::Profile::Puppetdb'] } }

      it { is_expected.not_to contain_class('influxdb::profile::toml') }
      it { is_expected.not_to contain_class('puppet_operational_dashboards::profile::postgres_access') }
    end

    context 'with an invalid template format' do
      let(:params) { { template_format: 'json' } }

      it { is_expected.to compile.and_raise_error(%r{template_format}) }
    end
  end
end
