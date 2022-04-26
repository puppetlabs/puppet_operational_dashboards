
require 'spec_helper_acceptance'

describe 'install dashboards and set up dependancies' do
  context 'apply enterprise_infrastructure  with default parameters' do
    it 'installs tomlrb and dbaccess' do
      inf = <<-MANIFEST
           service { 'pe-puppetserver': }
      include puppet_operational_dashboards::enterprise_infrastructure
     package { 'toml-rb puppet_gem':
       name     => 'toml-rb',
       ensure   => installed,
       provider => 'puppet_gem',
     }
           MANIFEST
      idempotent_apply(inf)
    end
  end
  context 'init puppet_operational_dashboards with default parameters' do
    it 'installs grafana and influxdb' do
      pp = <<-MANIFEST
        include puppet_operational_dashboards
        MANIFEST

      # Run it twice and then test for idempotency to cover token creation
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      idempotent_apply(pp)
    end
    describe port('3000') do
      it { is_expected.to be_listening }
    end

    # Influxdb should be listening on port 8086 by default
    describe port('8086') do
      it { is_expected.to be_listening }
    end

    it 'grafana has a data source' do
      curlquery = <<-QUERY
          curl -G http://admin:admin@127.0.0.1:3000/api/datasources/name/influxdb_puppet
          QUERY
      expect(run_shell(curlquery.to_s).stdout).to match(%r{influxdb_puppet})
    end
  end
end
