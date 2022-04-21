#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'puppet_operational_dashboards::pe_profiles_on_host' do
  context 'when using the function' do
    before :each do
      Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |_args|
        []
      end
    end

    it {
      is_expected.to run.and_return([])
    }
  end
end
