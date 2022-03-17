# frozen_string_literal: true

require 'singleton'
require 'serverspec'
require 'puppetlabs_spec_helper/module_spec_helper'
include PuppetLitmus

RSpec.configure do |c|
  c.mock_with :rspec
  c.before :suite do
    # Download the plugins and install required toml gem
    PuppetLitmus::PuppetHelpers.run_shell('/opt/puppetlabs/bin/puppet plugin download')
    pp = <<-PUPPETCODE
     service { 'pe-puppetserver': }
     include  influxdb::profile::toml
     package { 'toml-rb puppet_gem':
       name     => 'toml-rb',
       ensure   => installed,
       provider => 'puppet_gem',
     }
     PUPPETCODE
    apply_manifest(pp)
  end
end
