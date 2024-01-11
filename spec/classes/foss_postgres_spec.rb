# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::profile::foss_postgres_access' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) do
        <<-PRE_COND
          include puppetdb
          include puppetdb::master::config
        PRE_COND
      end
      let(:facts) { os_facts }

      it { is_expected.to compile }

      describe 'when using default parameters' do
        let(:pre_condition) do
          <<-PRE_COND
                include puppetdb
                include puppetdb::master::config
          PRE_COND
        end
        let(:params) do
          { telegraf_hosts: ['foo.bar.com'] }
        end

        it {
          is_expected.to contain_postgresql__server__role('telegraf').with(
            ensure: 'present',
            db: 'puppetdb',
          )

          is_expected.to contain_postgresql__server__database_grant('puppetdb grant connect to telegraf').with(
            privilege: 'CONNECT',
            db: 'puppetdb',
            role: 'telegraf',
          )
          is_expected.to contain_postgresql__server__database_grant('puppetdb grant connect to telegraf').that_requires('Postgresql::Server::Role[telegraf]')

          is_expected.to contain_postgresql__server__grant_role('monitoring').with(
            group: 'pg_monitor',
            role: 'telegraf',
          )
          is_expected.to contain_postgresql__server__grant_role('monitoring').that_requires('Postgresql::Server::Role[telegraf]')

          is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as telegraf (ipv4)').with(
            type: 'hostssl',
            database: 'puppetdb',
            user: 'telegraf',
            address: '0.0.0.0/0',
            auth_method: 'cert',
            order: 0,
            auth_option: 'map=puppetdb-telegraf-map clientcert=1',
          )

          is_expected.to contain_postgresql__server__pg_hba_rule('Allow certificate mapped connections to puppetdb as telegraf (ipv6)').with(
            type: 'hostssl',
            database: 'puppetdb',
            user: 'telegraf',
            address: '::0/0',
            auth_method: 'cert',
            order: 0,
            auth_option: 'map=puppetdb-telegraf-map clientcert=1',
          )

          is_expected.to contain_postgresql__server__pg_ident_rule('Map the SSL certificate of foo.bar.com as a puppetdb user').with(
            map_name: 'puppetdb-telegraf-map',
            system_username: 'foo.bar.com',
            database_username: 'telegraf',
          )
        }
      end
    end
  end
end
