require 'roundtrip'
require 'thor'
require 'roundtrip/store/redis'
require 'roundtrip/metrics/statsd'


class Roundtrip::CLI < Thor

  desc "start [ROUTE]", "starts a new trip on a given route"
  def start(route)
    t = core.start(route)
    say t.to_h
  end

  desc "end [TRIP_ID]", "ends a trip"
  def end(trip_id)
    t = core.end(trip_id)
    say t.to_h
  end

  method_option :redis
  method_option :statsd
  method_option :port
  desc "raw --port --redis [localhost:123] --statsd [localhost:456]", "start listening for raw events on a dedicated socket"
  def raw
    require 'roundtrip/raw'

    redis_host, redis_port    = (options[:redis] || "localhost:6379").split(':')
    statsd_host, statsd_port  = (options[:statsd] || "localhost:8125").split(':')
    Roundtrip.options[:redis]  = { :host  => redis_host, :port => redis_port.to_i }
    Roundtrip.options[:statsd] = { :host => statsd_host, :port => statsd_port.to_i }

    # XXX this bootstrapping code should really belong in some kind of bootstrap.rb
    # since web.rb already does this in `configure` block.
    store = Roundtrip::Store::Redis.new(Roundtrip.options)
    stats = Roundtrip::Metrics::Statsd.new(Roundtrip.options)
    Roundtrip::Raw.new(Roundtrip::Core.new(store, stats)).listen! (options[:port]||"5160").to_i
  end

private 
  def core
    @core = Roundtrip::Core.new(Roundtrip::Store::Redis.new)
  end
end
