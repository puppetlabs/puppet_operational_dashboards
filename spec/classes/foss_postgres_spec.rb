# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::profile::foss_postgres_access' do
  let(:pre_condition) do
    <<-PRE_COND
      include puppetdb
      include puppetdb::master::config
    PRE_COND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'when using default parameters' do
        let(:params) do
          { telegraf_hosts: ['foo.bar.com'] }
        end

        it {
          is_expected.to contain_postgresql__server__role('telegraf').with(
            ensure: 'present',
            db: 'puppetdb',
          )
        }

        it {
          is_expected.to contain_postgresql__server__database_grant('puppetdb grant connect to telegraf').with(
            privilege: 'CONNECT',
            db: 'puppetdb',
            role: 'telegraf',
          )
          is_expected.to contain_postgresql__server__database_grant('puppetdb grant connect to telegraf').that_requires('Postgresql::Server::Role[telegraf]')
        }

        it {
          is_expected.to contain_postgresql__server__grant_role('monitoring').with(
            group: 'pg_monitor',
            role: 'telegraf',
          )
          is_expected.to contain_postgresql__server__grant_role('monitoring').that_requires('Postgresql::Server::Role[telegraf]')
        }

        it {
          is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as telegraf (ipv4)').with(
            type: 'hostssl',
            database: 'puppetdb',
            user: 'telegraf',
            address: '0.0.0.0/0',
            auth_method: 'cert',
            order: 0,
            auth_option: 'map=puppetdb-telegraf-map clientcert=1',
          )
        }

        it {
          is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as telegraf (ipv6)').with(
            type: 'hostssl',
            database: 'puppetdb',
            user: 'telegraf',
            address: '::0/0',
            auth_method: 'cert',
            order: 0,
            auth_option: 'map=puppetdb-telegraf-map clientcert=1',
          )
        }

        it {
          is_expected.to contain_postgresql__server__pg_ident_rule('Map the SSL certificate of foo.bar.com as a puppetdb user').with(
            map_name: 'puppetdb-telegraf-map',
            system_username: 'foo.bar.com',
            database_username: 'telegraf',
          )
        }
      end
    end
  end

  context 'with default facts' do
    let(:facts) { on_supported_os['redhat-9-x86_64'] }

    context 'when using a custom telegraf user and multiple hosts' do
      let(:params) do
        { telegraf_user: 'metrics', telegraf_hosts: ['dashboards.foo.com', 'compiler.foo.com'] }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_postgresql__server__role('metrics') }
      it { is_expected.to contain_postgresql__server__database_grant('puppetdb grant connect to metrics').with_role('metrics') }
      it { is_expected.to contain_postgresql__server__grant_role('monitoring').with_role('metrics') }
      it { is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as metrics (ipv4)').with_user('metrics') }
      it { is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as metrics (ipv6)').with_user('metrics') }

      it {
        ['dashboards.foo.com', 'compiler.foo.com'].each do |host|
          is_expected.to contain_postgresql__server__pg_ident_rule("Map the SSL certificate of #{host} as a puppetdb user").with(
            system_username: host,
            database_username: 'metrics',
          )
        end
      }
    end

    context 'when no telegraf hosts are found' do
      it { is_expected.to compile }
      it { is_expected.to contain_postgresql__server__role('telegraf') }
      it { expect(catalogue.resources.map(&:type)).not_to include('Postgresql::Server::Pg_ident_rule') }
    end
  end
end
