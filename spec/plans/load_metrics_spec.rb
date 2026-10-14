# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

begin
  require 'bolt_spec/plans'
rescue LoadError
  # Plan specs need the bolt gem, which is installed from the puppetcore gem source
end

describe 'puppet_operational_dashboards::load_metrics', if: defined?(BoltSpec::Plans) do
  include BoltSpec::Plans if defined?(BoltSpec::Plans)

  let(:plan) { 'puppet_operational_dashboards::load_metrics' }
  let(:script) { 'puppet_operational_dashboards/plan_files/import_archives.sh' }
  let(:target) { 'dashboards.foo.com' }

  let(:tmpdir) { Dir.mktmpdir }
  let(:support_script) { File.join(tmpdir, 'puppet_enterprise_support_host.tar.gz').tap { |f| File.write(f, '') } }
  let(:metrics_dir) { File.join(tmpdir, 'metrics').tap { |d| Dir.mkdir(d) } }

  before(:each) { BoltSpec::Plans.init }

  after(:each) do
    Puppet[:tasks] = false
    FileUtils.rm_rf(tmpdir)
  end

  context 'with invalid parameters' do
    it 'only accepts a single target' do
      result = run_plan(plan, 'targets' => ['a.foo.com', 'b.foo.com'], 'metrics_dir' => metrics_dir)
      expect(result).not_to be_ok
      expect(result.value.msg).to eq('This plan only accepts a single target.')
    end

    it 'requires a metrics directory or support script' do
      result = run_plan(plan, 'targets' => target)
      expect(result).not_to be_ok
      expect(result.value.msg).to eq('Must specify one of $metrics_dir or $support_script_file')
    end

    it 'does not accept both a metrics directory and a support script' do
      result = run_plan(plan, 'targets' => target, 'metrics_dir' => metrics_dir, 'support_script_file' => support_script)
      expect(result).not_to be_ok
      expect(result.value.msg).to eq('$metrics_dir and $support_script_file are mutually exclusive')
    end
  end

  context 'when loading a support script' do
    it 'configures the target, uploads the support script, and imports it' do
      allow_apply_prep
      allow_apply
      expect(executor).to receive(:queue_execute).once.and_call_original
      expect_upload(support_script).with_destination('/tmp').with_targets([target])
      expect_script(script).with_targets([target]).with_params(
        'arguments' => ['-t', '/tmp/telegraf', '-s', '/tmp/puppet_enterprise_support_host.tar.gz', '-c', 'true'],
      ).always_return('stdout' => 'imported')

      result = run_plan(plan, 'targets' => target, 'support_script_file' => support_script)
      expect(result).to be_ok
      expect(result.value.first.value['stdout']).to eq('imported')
    end

    it 'passes custom directories and cleanup settings to the import script' do
      allow_apply_prep
      allow_apply
      expect_upload(support_script).with_destination('/var/tmp').with_targets([target])
      expect_script(script).with_targets([target]).with_params(
        'arguments' => ['-t', '/opt/telegraf_import', '-s', '/var/tmp/puppet_enterprise_support_host.tar.gz', '-c', 'false'],
      )

      result = run_plan(
        plan,
        'targets' => target,
        'support_script_file' => support_script,
        'dest_dir' => '/var/tmp',
        'conf_dir' => '/opt/telegraf_import',
        'cleanup_metrics' => 'false',
      )
      expect(result).to be_ok
    end
  end

  context 'when loading a metrics directory' do
    it 'configures the target, uploads the metrics, and imports them' do
      allow_apply_prep
      allow_apply
      expect(executor).to receive(:queue_execute).once.and_call_original
      expect_upload(metrics_dir).with_destination('/tmp').with_targets([target])
      expect_script(script).with_targets([target]).with_params(
        'arguments' => ['-t', '/tmp/telegraf', '-m', '/tmp', '-c', 'true'],
      )

      result = run_plan(plan, 'targets' => target, 'metrics_dir' => metrics_dir)
      expect(result).to be_ok
    end
  end

  it 'fails when the import script fails' do
    allow_apply_prep
    allow_apply
    allow_upload(support_script)
    expect_script(script).error_with('kind' => 'puppetlabs.tasks/command-error', 'msg' => 'import failed')

    result = run_plan(plan, 'targets' => target, 'support_script_file' => support_script)
    expect(result).not_to be_ok
    expect(result.value.message).to eq("run_script '#{script}' failed on 1 target")
    expect(result.value.result_set.first.error_hash['msg']).to eq('import failed')
  end
end
