require 'redis'
require 'redis/connection/memory'

module Fakeredis
  Redis = ::Redis
end
