#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'puppet_operational_dashboards::hosts_with_profile' do
  context 'when using the function' do
    before :each do
      Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |_args|
        []
      end
    end

    it {
      is_expected.to run.with_params('Puppet_enterprise::Profile::Master').and_return([])
      is_expected.to run.with_params('Puppet_enterprise::Profile::Puppetdb').and_return([])
      is_expected.to run.with_params('Puppet_enterprise::Profile::Database').and_return([])
    }
  end
end
