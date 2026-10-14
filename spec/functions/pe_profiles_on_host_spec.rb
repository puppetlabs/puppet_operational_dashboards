# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::pe_profiles_on_host' do
  let(:node) { 'primary.foo.com' }
  let(:queries) { [] }
  let(:query_result) { [] }

  before(:each) do
    recorded = queries
    result = query_result
    Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |args|
      recorded << args[0]
      result
    end
  end

  context 'without storeconfigs' do
    before(:each) { Puppet[:storeconfigs] = false }

    it { is_expected.to run.and_return([]) }

    it 'does not query PuppetDB' do
      is_expected.to run
      expect(queries).to be_empty
    end
  end

  context 'with storeconfigs' do
    before(:each) { Puppet[:storeconfigs] = true }
    after(:each) { Puppet[:storeconfigs] = false }

    context 'when PuppetDB returns no profiles' do
      it { is_expected.to run.and_return([]) }
    end

    context 'when PuppetDB returns profiles' do
      let(:query_result) { [{ 'title' => 'Puppet_enterprise::Profile::Master' }, { 'title' => 'Puppet_enterprise::Profile::Puppetdb' }] }

      it { is_expected.to run.and_return(['Puppet_enterprise::Profile::Master', 'Puppet_enterprise::Profile::Puppetdb']) }

      it 'queries the PE profiles of the node compiling the catalog' do
        is_expected.to run
        expect(queries.size).to eq(1)

        query = queries.first.gsub(%r{\s+}, ' ').strip
        expect(query).to eq(
          "resources[title] { type = 'Class' and certname = 'primary.foo.com' and " \
          "title in ['Puppet_enterprise::Profile::Puppetdb', 'Puppet_enterprise::Profile::Master', " \
          "'Puppet_enterprise::Profile::Database', 'Puppet_enterprise::Profile::Orchestrator'] and " \
          'nodes { deactivated is null and expired is null } }',
        )
      end
    end
  end

  context 'with invalid parameters' do
    it { is_expected.to run.with_params('foo').and_raise_error(ArgumentError) }
  end
end
