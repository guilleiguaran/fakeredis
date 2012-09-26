require "spec_helper"

# Remove memory so we test against actual redis
Redis::Connection.drivers.pop

RSpec.configure do |config|
  config.before(:each) do
    Redis.new.flushall
  end
end

def fakeredis?
  false
end
