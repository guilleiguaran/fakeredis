require 'redis'
require 'redis/connection/memory'

module FakeRedis
  Redis = ::Redis
end
