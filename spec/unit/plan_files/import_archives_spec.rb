# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tmpdir'
require 'fileutils'

describe 'import_archives.sh' do
  let(:script) { File.expand_path('../../../files/plan_files/import_archives.sh', __dir__) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:bin_dir) { File.join(tmpdir, 'bin').tap { |d| FileUtils.mkdir_p(d) } }
  let(:telegraf_dir) { File.join(tmpdir, 'telegraf').tap { |d| FileUtils.mkdir_p(d) } }
  let(:telegraf_log) { File.join(tmpdir, 'telegraf.log') }

  after(:each) { FileUtils.rm_rf(tmpdir) }

  # A fake telegraf that records its arguments and the files it can see
  before(:each) do
    File.write(File.join(bin_dir, 'telegraf'), <<~SCRIPT)
      #!/bin/sh
      echo "$*" >> "#{telegraf_log}"
      echo "fake telegraf output"
    SCRIPT
    FileUtils.chmod(0o755, File.join(bin_dir, 'telegraf'))
  end

  def run_script(*args)
    env = { 'PATH' => "#{bin_dir}:#{ENV.fetch('PATH', nil)}" }
    Open3.capture3(env, 'bash', script, *args)
  end

  def telegraf_calls
    File.readlines(telegraf_log, chomp: true)
  end

  # Creates a metrics directory as found in a support script, with optional sar archives
  def create_metrics(root, sar_archives: false)
    FileUtils.mkdir_p(File.join(root, 'metrics', 'puppetserver'))
    File.write(File.join(root, 'metrics', 'puppetserver', 'data.json'), '{}')
    return unless sar_archives

    FileUtils.mkdir_p(File.join(root, 'metrics', 'sa'))
    File.write(File.join(root, 'metrics', 'sa', 'sa01'), 'sar')
  end

  context 'when importing a metrics directory' do
    let(:metrics_dir) { File.join(tmpdir, 'upload').tap { |d| create_metrics(d) } }

    it 'runs telegraf with the configuration directory and the metrics collector sar config' do
      stdout, _stderr, status = run_script('-t', telegraf_dir, '-m', metrics_dir, '-c', 'false')

      expect(status.exitstatus).to eq(0)
      expect(telegraf_calls).to eq(
        [
          "--once --debug --config #{telegraf_dir}/telegraf.conf --config-directory #{telegraf_dir}/telegraf.conf.d",
          "--once --debug --config #{telegraf_dir}/telegraf.conf --config #{telegraf_dir}/sar.conf",
        ],
      )
      expect(stdout).to include('fake telegraf output')
    end

    it 'keeps the metrics when cleanup is false' do
      run_script('-t', telegraf_dir, '-m', metrics_dir, '-c', 'false')
      expect(File).to exist(File.join(metrics_dir, 'metrics'))
    end

    it 'keeps the metrics when cleanup is not requested' do
      run_script('-t', telegraf_dir, '-m', metrics_dir)
      expect(File).to exist(File.join(metrics_dir, 'metrics'))
    end

    it 'removes the metrics when cleanup is true' do
      _stdout, _stderr, status = run_script('-t', telegraf_dir, '-m', metrics_dir, '-c', 'true')
      expect(status.exitstatus).to eq(0)
      expect(File).not_to exist(File.join(metrics_dir, 'metrics'))
    end

    it 'extracts compressed metrics before running telegraf' do
      archive_dir = File.join(metrics_dir, 'metrics', 'puppetdb')
      FileUtils.mkdir_p(File.join(tmpdir, 'src'))
      File.write(File.join(tmpdir, 'src', 'puppetdb.json'), '{}')
      FileUtils.mkdir_p(archive_dir)
      system('tar', 'czf', File.join(archive_dir, 'puppetdb.tar.gz'), '-C', File.join(tmpdir, 'src'), 'puppetdb.json', exception: true)

      run_script('-t', telegraf_dir, '-m', metrics_dir, '-c', 'false')
      expect(File).to exist(File.join(archive_dir, 'puppetdb.json'))
    end
  end

  context 'when importing a metrics directory with system sar archives' do
    let(:metrics_dir) { File.join(tmpdir, 'upload').tap { |d| create_metrics(d, sar_archives: true) } }

    it 'prefers the system sar config' do
      run_script('-t', telegraf_dir, '-m', metrics_dir, '-c', 'false')
      expect(telegraf_calls.last).to eq("--once --debug --config #{telegraf_dir}/telegraf.conf --config #{telegraf_dir}/system_sar.conf")
    end
  end

  context 'when importing a support script' do
    let(:support_script) do
      source = File.join(tmpdir, 'support_script')
      create_metrics(File.join(source, 'puppet_enterprise_support_host'), sar_archives: true)
      tarball = File.join(tmpdir, 'support.tar.gz')
      system('tar', 'czf', tarball, '-C', source, 'puppet_enterprise_support_host', exception: true)
      tarball
    end

    it 'extracts the support script and runs telegraf from it' do
      _stdout, _stderr, status = run_script('-t', telegraf_dir, '-s', support_script, '-c', 'false')

      expect(status.exitstatus).to eq(0)
      expect(telegraf_calls.size).to eq(2)
      expect(telegraf_calls.last).to end_with('system_sar.conf')
      expect(File).to exist(support_script)
    end

    it 'removes the support script and extracted files when cleanup is true' do
      _stdout, _stderr, status = run_script('-t', telegraf_dir, '-s', support_script, '-c', 'true')

      expect(status.exitstatus).to eq(0)
      expect(File).not_to exist(support_script)
      expect(Dir.children(telegraf_dir).select { |f| File.directory?(File.join(telegraf_dir, f)) }).to be_empty
    end

    it 'fails when the support script cannot be extracted' do
      bad = File.join(tmpdir, 'bad.tar.gz')
      File.write(bad, 'not a tarball')

      stdout, _stderr, status = run_script('-t', telegraf_dir, '-s', bad, '-c', 'true')
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include("Failed to extract #{bad}")
      expect(File).not_to exist(telegraf_log)
    end
  end

  it 'warns about invalid options' do
    metrics_dir = File.join(tmpdir, 'upload').tap { |d| create_metrics(d) }
    stdout, _stderr, _status = run_script('-x', '-t', telegraf_dir, '-m', metrics_dir)
    expect(stdout).to include('WARN: invalid option ? received')
  end
end
