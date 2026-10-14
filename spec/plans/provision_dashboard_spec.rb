# frozen_string_literal: true

require 'spec_helper'

begin
  require 'bolt_spec/plans'
rescue LoadError
  # Plan specs need the bolt gem, which is installed from the puppetcore gem source
end

describe 'puppet_operational_dashboards::provision_dashboard', if: defined?(BoltSpec::Plans) do
  include BoltSpec::Plans if defined?(BoltSpec::Plans)

  before(:each) { BoltSpec::Plans.init }
  after(:each) { Puppet[:tasks] = false }

  it 'prepares the targets and applies the dashboards class twice' do
    allow_apply_prep
    allow_apply
    expect(executor).to receive(:queue_execute).twice.and_call_original

    result = run_plan('puppet_operational_dashboards::provision_dashboard', 'targets' => ['dashboards.foo.com'])
    expect(result).to be_ok
  end

  it 'fails when apply is not possible' do
    allow_apply_prep

    result = run_plan('puppet_operational_dashboards::provision_dashboard', 'targets' => ['dashboards.foo.com'])
    expect(result).not_to be_ok
    expect(result.value.message).to match(%r{Unexpected call to apply})
  end
end
