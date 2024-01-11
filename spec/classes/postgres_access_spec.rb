# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::profile::postgres_access' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-PRE_COND
        class pe_postgresql::server {}
        include pe_postgresql::server
        define pe_postgresql_psql(
          $db,
          $port,
          $psql_user,
          $psql_group,
          $unless,
          $psql_path,
          $command = 'foo',
        ) {}
        define pe_postgresql::server::database_grant(
          $privilege,
          $db,
          $role
        ) {}
        define puppet_enterprise::pg::cert_allowlist_entry(
          $user,
          $database,
          $allowed_client_certname,
          $pg_ident_conf_path,
          $ip_mask_allow_all_users_ssl,
          $ipv6_mask_allow_all_users_ssl,
        ) {}
        PRE_COND
      end

      it { is_expected.to compile }
    end
  end

  context 'on puppet enterprise' do
    let(:pre_condition) do
      <<-PRE_COND
      class pe_postgresql::server {}
      include pe_postgresql::server
      define pe_postgresql_psql(
        $db,
        $port,
        $psql_user,
        $psql_group,
        $unless,
        $psql_path,
        $command = 'foo',
      ) {}
      define pe_postgresql::server::database_grant(
        $privilege,
        $db,
        $role
      ) {}
        define puppet_enterprise::pg::cert_allowlist_entry(
          $user,
          $database,
          $allowed_client_certname,
          $pg_ident_conf_path,
          $ip_mask_allow_all_users_ssl,
          $ipv6_mask_allow_all_users_ssl,
        ) {}
      PRE_COND
    end

    context 'when using default parameters' do
      let(:params) do
        { telegraf_hosts: ['foo.bar.com'] }
      end

      it {
        is_expected.to contain_pe_postgresql_psql('CREATE ROLE telegraf LOGIN').with(
          db: 'pe-puppetdb',
          port: '5432',
          psql_user: 'pe-postgres',
          psql_group: 'pe-postgres',
          unless: "SELECT rolname FROM pg_roles WHERE rolname='telegraf'",
          psql_path: '/opt/puppetlabs/server/bin/psql',
        )
        is_expected.to contain_pe_postgresql_psql('CREATE ROLE telegraf LOGIN').that_requires('Class[pe_postgresql::server]')

        is_expected.to contain_pe_postgresql__server__database_grant('operational_dashboards_telegraf').with(
          privilege: 'CONNECT',
          db: 'pe-puppetdb',
          role: 'telegraf',
        )
        is_expected.to contain_pe_postgresql__server__database_grant('operational_dashboards_telegraf').that_requires('Pe_postgresql_psql[CREATE ROLE telegraf LOGIN]')

        is_expected.to contain_pe_postgresql_psql('telegraf_pg_monitor_grant').with(
          db: 'pe-puppetdb',
          port: '5432',
          psql_user: 'pe-postgres',
          psql_group: 'pe-postgres',
          command: 'GRANT pg_monitor TO telegraf',
          unless: "select 1 from pg_roles where pg_has_role( 'telegraf', 'pg_monitor', 'member')",
          psql_path: '/opt/puppetlabs/server/bin/psql',
        )
        is_expected.to contain_pe_postgresql_psql('telegraf_pg_monitor_grant').that_requires('Pe_postgresql_psql[CREATE ROLE telegraf LOGIN]')

        is_expected.to contain_puppet_enterprise__pg__cert_allowlist_entry('telegraf_foo.bar.com').with(
          user: 'telegraf',
          database: 'pe-puppetdb',
          allowed_client_certname: 'foo.bar.com',
          pg_ident_conf_path: '/opt/puppetlabs/server/data/postgresql/14/data/pg_ident.conf',
          ip_mask_allow_all_users_ssl: '0.0.0.0/0',
          ipv6_mask_allow_all_users_ssl: '::/0',
        )
      }
    end
  end
end
