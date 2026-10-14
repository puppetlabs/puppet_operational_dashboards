# frozen_string_literal: true

# rspec-puppet resolves Deferred values after compiling a catalog, which calls functions such as
# influxdb::retrieve_token for real. This helper keeps that hermetic and records the unresolved
# Deferred values so specs can assert on the function calls a node would make at apply time.
module DeferredCapture
  class << self
    # Recorded values keyed by catalog, as rspec-puppet caches compiled catalogs between examples
    def values
      @values ||= Hash.new { |h, k| h[k] = {} }
    end

    def deferred_class
      Puppet::Pops::Types::TypeFactory.deferred.implementation_class
    end

    def contains_deferred?(value)
      case value
      when deferred_class then true
      when Puppet::Pops::Types::PSensitiveType::Sensitive then contains_deferred?(value.unwrap)
      when Array then value.any? { |v| contains_deferred?(v) }
      when Hash then value.any? { |k, v| contains_deferred?(k) || contains_deferred?(v) }
      else false
      end
    end

    def record(catalog)
      catalog.resources.each do |resource|
        resource.to_hash.each do |param, value|
          values[catalog.object_id][[resource.ref, param]] = value if contains_deferred?(value)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.before(:each) do
    # Never contact a real InfluxDB server from unit tests
    http_client = instance_double(Puppet::HTTP::Client)
    allow(http_client).to receive(:get).and_raise(Puppet::HTTP::ConnectionError, 'HTTP disabled in unit tests')
    allow(Puppet.runtime).to receive(:[]).and_call_original
    allow(Puppet.runtime).to receive(:[]).with(:http).and_return(http_client)

    allow(Puppet::Pops::Evaluator::DeferredResolver).to receive(:resolve_and_replace).and_wrap_original do |original, facts, catalog, *args|
      DeferredCapture.record(catalog)
      original.call(facts, catalog, *args)
    end
  end
end

# Returns the unresolved value of a resource parameter that contained a Deferred value
# @param ref [String] Resource reference, e.g. 'File[/etc/foo]'
# @param param [Symbol] Parameter name
def deferred_param(ref, param)
  recorded = DeferredCapture.values[catalogue.object_id]
  recorded.fetch([ref, param]) do
    raise KeyError, "#{ref} has no Deferred value for #{param}. Recorded: #{recorded.keys.inspect}"
  end
end

# Returns the function name and arguments of a Deferred value, unwrapping Sensitive
def deferred_call(value)
  value = value.unwrap if value.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
  raise ArgumentError, "Expected a Deferred value, got #{value.class}" unless value.is_a?(DeferredCapture.deferred_class)

  [value.name, value.arguments]
end
