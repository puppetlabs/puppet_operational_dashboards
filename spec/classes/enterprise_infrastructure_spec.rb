# frozen_string_literal: true

require 'spec_helper'

describe 'puppet_operational_dashboards::enterprise_infrastructure' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-PRE_COND
        class influxdb::profile::toml {}
        PRE_COND
      end

      it { is_expected.to compile }
    end
  end
end
