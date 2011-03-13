
module FakeRedis
  class Redis

    def self.connect(options = {})
      new(options)
    end

    def initialize(options = {})
      @data = {}
      @expires = {}
    end
  end
end

require "fakeredis/connection"
require "fakeredis/keys"
require "fakeredis/strings"
require "fakeredis/hashes"
require "fakeredis/lists"
require "fakeredis/transactions"
require "fakeredis/server"
