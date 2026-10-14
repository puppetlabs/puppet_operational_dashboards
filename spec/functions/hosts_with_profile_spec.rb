# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::hosts_with_profile' do
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

    it { is_expected.to run.with_params('Puppet_enterprise::Profile::Master').and_return([]) }

    it 'does not query PuppetDB' do
      is_expected.to run.with_params('Puppet_enterprise::Profile::Master')
      expect(queries).to be_empty
    end
  end

  context 'with storeconfigs' do
    before(:each) { Puppet[:storeconfigs] = true }
    after(:each) { Puppet[:storeconfigs] = false }

    context 'when PuppetDB returns no nodes' do
      it { is_expected.to run.with_params('Puppet_enterprise::Profile::Master').and_return([]) }
      it { is_expected.to run.with_params('Puppet_enterprise::Profile::Puppetdb').and_return([]) }
      it { is_expected.to run.with_params('Puppet_enterprise::Profile::Database').and_return([]) }
    end

    context 'when PuppetDB returns nodes' do
      let(:query_result) { [{ 'certname' => 'primary.foo.com' }, { 'certname' => 'compiler.foo.com' }] }

      it { is_expected.to run.with_params('Puppet_enterprise::Profile::Master').and_return(['primary.foo.com', 'compiler.foo.com']) }

      it 'queries active nodes with the given class' do
        is_expected.to run.with_params('Puppet_operational_dashboards::Telegraf::Agent')
        expect(queries.size).to eq(1)

        query = queries.first.gsub(%r{\s+}, ' ').strip
        expect(query).to eq(
          "resources[certname] { type = 'Class' and title = 'Puppet_operational_dashboards::Telegraf::Agent' and " \
          'nodes { deactivated is null and expired is null } }',
        )
      end
    end
  end

  context 'with invalid parameters' do
    it { is_expected.to run.with_params.and_raise_error(ArgumentError) }
    it { is_expected.to run.with_params(1).and_raise_error(ArgumentError) }
    it { is_expected.to run.with_params('a', 'b').and_raise_error(ArgumentError) }
  end
end
