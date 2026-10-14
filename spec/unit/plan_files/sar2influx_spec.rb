# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

load File.expand_path('../../../files/plan_files/sar2influx.rb', __dir__)

describe 'sar2influx.rb' do
  let(:cli_class) { PBug::ImportSARMetrics::CLI }

  # Writes a fake sadf executable to a temporary directory placed first on the PATH
  def with_fake_sadf(version: '12.5.4', data: '', convert_message: 'File format already up-to-date')
    Dir.mktmpdir do |dir|
      sadf = File.join(dir, 'sadf')
      File.write(sadf, <<~SCRIPT)
        #!/bin/sh
        if [ "$1" = "-V" ]; then
          echo "sadf: sysstat version #{version}"
        elif [ "$1" = "-c" ]; then
          echo "#{convert_message}" >&2
        elif [ "$1" = "-Up" ]; then
          printf '%s' '#{data}'
        fi
      SCRIPT
      FileUtils.chmod(0o755, sadf)

      original_path = ENV.fetch('PATH', nil)
      ENV['PATH'] = "#{dir}:#{original_path}"
      begin
        yield sadf
      ensure
        ENV['PATH'] = original_path
      end
    end
  end

  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    result = yield
    [result, $stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  describe PBug::ImportSARMetrics::StandardOutput do
    it 'writes data to stdout' do
      _result, stdout, _stderr = capture_output { described_class.new.write('data') }
      expect(stdout).to eq('data')
    end

    it 'ignores a closed stdout' do
      allow($stdout).to receive(:write).and_raise(Errno::EPIPE)
      expect { described_class.new.write('data') }.not_to raise_error
    end
  end

  describe PBug::ImportSARMetrics::InfluxDBOutput do
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPResponse, code: '204', message: 'No Content') }
    let(:token_file) { Tempfile.create('influxdb_token').tap { |f| f.write("secret-token\n") }.tap(&:close) }
    let(:url) { 'http://influx.foo.com:8086/api/v2/write?bucket=puppet_data&org=puppetlabs&precision=s' }

    before(:each) do
      allow(Net::HTTP).to receive(:new).with('influx.foo.com', 8086).and_return(http)
      allow(http).to receive(:keep_alive_timeout=)
      allow(http).to receive(:start)
      allow(http).to receive(:finish)
    end

    after(:each) { File.unlink(token_file.path) }

    it 'posts data to InfluxDB with the token from the token file' do
      expect(http).to receive(:keep_alive_timeout=).with(20)
      expect(http).to receive(:finish)
      expect(http).to receive(:request) do |request, data|
        expect(request).to be_a(Net::HTTP::Post)
        expect(request.path).to eq('/api/v2/write?bucket=puppet_data&org=puppetlabs&precision=s')
        expect(request['Authorization']).to eq('Token secret-token')
        expect(request['Connection']).to eq('keep-alive')
        expect(data).to eq("sar,server=a value=1 1\n")
        response
      end

      _result, _stdout, stderr = capture_output do
        output = described_class.new(url, token_file.path)
        output.write("sar,server=a value=1 1\n")
        output.close
      end

      expect(stderr).to include('INFO: Connecting to InfluxDB server at influx.foo.com:8086')
      expect(stderr).to include('204: No Content')
      expect(stderr).to include('INFO: Closing connection to InfluxDB server at influx.foo.com:8086')
    end

    it 'only closes the connection once' do
      expect(http).to receive(:finish).once

      capture_output do
        output = described_class.new(url, token_file.path)
        output.close
        output.close
      end
    end
  end

  describe PBug::ImportSARMetrics::CLI do
    describe '#run' do
      it 'shows help' do
        result, stdout, _stderr = capture_output { cli_class.new(['--help']).run }
        expect(result).to eq(0)
        expect(stdout).to include('Usage: sar2influxdb.rb [options]')
        expect(stdout).to include('--db-host')
      end

      it 'shows the version' do
        result, stdout, _stderr = capture_output { cli_class.new(['--version']).run }
        expect(result).to eq(0)
        expect(stdout).to eq("#{PBug::ImportSARMetrics::VERSION}\n")
      end

      it 'fails when no data files are given' do
        result, _stdout, stderr = capture_output { cli_class.new([]).run }
        expect(result).to eq(1)
        expect(stderr).to include('ERROR: No data files to parse.')
      end

      it 'fails when the pattern matches no files' do
        result, _stdout, stderr = capture_output { cli_class.new(['--pattern', '/nonexistent/sa??']).run }
        expect(result).to eq(1)
        expect(stderr).to include('ERROR: No data files to parse.')
      end

      it 'requires --db-name with --db-host' do
        with_fake_sadf do
          result, _stdout, stderr = capture_output { cli_class.new(['--db-host', 'influx.foo.com', 'sa01']).run }
          expect(result).to eq(1)
          expect(stderr).to include('ERROR ArgumentError: --db-name must be used with --db-host.')
        end
      end

      it 'requires a readable token file with --db-host' do
        with_fake_sadf do
          result, _stdout, stderr = capture_output do
            cli_class.new(['--db-host', 'influx.foo.com', '--db-name', 'puppet_data', '--db-token', '/nonexistent/token', 'sa01']).run
          end
          expect(result).to eq(1)
          expect(stderr).to include('Use --db-token to specify a file with an InfluxDB access token.')
        end
      end

      it 'includes a backtrace in errors when debugging' do
        with_fake_sadf do
          _result, _stdout, stderr = capture_output { cli_class.new(['--debug', '--db-host', 'influx.foo.com', 'sa01']).run }
          expect(stderr).to match(%r{ERROR ArgumentError: --db-name must be used with --db-host.\n\t.+sar2influx\.rb})
        end
      end

      it 'converts sar archives to line protocol on stdout' do
        data = "host.foo.com\t600\t1700000000\tall\t%user\t1.50\n" \
               "host.foo.com\t600\t1700000000\teth0\trxpck/s\t20.00\n" \
               "host.foo.com\t600\t1700000300\tLINUX-RESTART\t\n"

        with_fake_sadf(data: data) do
          result, stdout, stderr = capture_output { cli_class.new(['sa01']).run }
          expect(result).to eq(0)
          expect(stdout).to eq(
            "sar,server=host-foo-com,name=%user,device=all value=1.50 1700000000000000000\n" \
            "sar,server=host-foo-com,name=rxpck/s,device=eth0 value=20.00 1700000000000000000\n",
          )
          expect(stderr).to include('INFO: Processing sa01')
          expect(stderr).to include('version: 12.5.4')
        end
      end

      it 'sends converted data to InfluxDB' do
        output = instance_double(PBug::ImportSARMetrics::InfluxDBOutput)
        token = Tempfile.create('influxdb_token')
        allow(PBug::ImportSARMetrics::InfluxDBOutput).to receive(:new).with(
          'http://influx.foo.com:8086/api/v2/write?bucket=puppet_data&org=puppetlabs&precision=s', token.path
        ).and_return(output)
        expect(output).to receive(:write).with("sar,server=host,name=%user,device=all value=1.50 1700000000000000000\n")
        expect(output).to receive(:close)

        with_fake_sadf(data: "host\t600\t1700000000\tall\t%user\t1.50\n") do
          result, _stdout, _stderr = capture_output do
            cli_class.new(['--db-host', 'influx.foo.com', '--db-name', 'puppet_data', '--db-token', token.path, 'sa01']).run
          end
          expect(result).to eq(0)
        end
      ensure
        File.unlink(token.path)
      end

      it 'reads options from task environment variables' do
        output = instance_double(PBug::ImportSARMetrics::InfluxDBOutput, write: nil)
        token = Tempfile.create('influxdb_token')
        expect(output).to receive(:close)
        allow(PBug::ImportSARMetrics::InfluxDBOutput).to receive(:new).with(
          'http://task.foo.com:8086/api/v2/write?bucket=task_bucket&org=puppetlabs&precision=s', token.path
        ).and_return(output)

        with_fake_sadf do
          ENV['PT_db_host'] = 'task.foo.com'
          ENV['PT_db_name'] = 'task_bucket'
          ENV['PT_db_token'] = token.path
          result, _stdout, _stderr = capture_output { cli_class.new(['sa01']).run }
          expect(result).to eq(0)
        ensure
          ['PT_db_host', 'PT_db_name', 'PT_db_token'].each { |var| ENV.delete(var) }
        end
      ensure
        File.unlink(token.path)
      end
    end

    describe '#find_sar_commands!' do
      subject(:cli) { cli_class.new([]) }

      it 'finds a supported sadf' do
        with_fake_sadf(version: '11.1.1') do |sadf|
          _result, _stdout, stderr = capture_output { cli.find_sar_commands! }
          expect(stderr).to include("INFO: using #{sadf} version: 11.1.1")
        end
      end

      it 'rejects an old sysstat version' do
        with_fake_sadf(version: '10.2.0') do
          expect { cli.find_sar_commands! }.to raise_error(RuntimeError, %r{requires sysstat 11\.1\.1 or newer.*10\.2\.0})
        end
      end

      it 'fails when sadf is not found' do
        original_path = ENV.fetch('PATH', nil)
        ENV['PATH'] = '/nonexistent'
        expect { cli.find_sar_commands! }.to raise_error(RuntimeError, %r{requires sadf from the Linux sysstat package})
      ensure
        ENV['PATH'] = original_path
      end
    end

    describe '#parse_sar_archive' do
      subject(:cli) { cli_class.new([]) }

      it 'parses each sadf line into a hash and skips one-off events' do
        data = "host.foo.com\t600\t1700000000\tall\t%user\t1.50\nhost.foo.com\t600\t1700000300\tLINUX-RESTART\n"

        with_fake_sadf(data: data) do
          capture_output { cli.find_sar_commands! }
          entries = cli.parse_sar_archive('sa01').to_a
          expect(entries).to eq([{ hostname: 'host.foo.com', interval: '600', timestamp: '1700000000', name: 'all', field: '%user', value: '1.50' }])
        end
      end

      it 'reads archives converted to the current sysstat format' do
        with_fake_sadf(data: "host\t600\t1700000000\tall\t%user\t1.50\n", convert_message: 'Conversion successful') do
          capture_output { cli.find_sar_commands! }
          expect(cli.parse_sar_archive('sa01').to_a.size).to eq(1)
        end
      end
    end

    describe '#format_sar_data' do
      subject(:cli) { cli_class.new([]) }

      it 'formats entries as InfluxDB line protocol' do
        data = [
          { hostname: +'a.b.c', interval: '600', timestamp: '1', name: 'all', field: '%user', value: '1' },
          { hostname: +'a.b.c', interval: '600', timestamp: '2', name: '-', field: 'proc/s', value: '2' },
          { hostname: +'a.b.c', interval: '600', timestamp: '3', name: 'sda', field: 'tps', value: '3' },
          { hostname: +'a.b.c', interval: '600', timestamp: '4', name: 'LINUX-RESTART', field: 'x', value: '4' },
        ]

        expect(cli.format_sar_data(data)).to eq(
          [
            'sar,server=a-b-c,name=%user,device=all value=1 1000000000',
            'sar,server=a-b-c,name=proc/s,device=all value=2 2000000000',
            'sar,server=a-b-c,name=tps,device=sda value=3 3000000000',
          ],
        )
      end
    end
  end
end
