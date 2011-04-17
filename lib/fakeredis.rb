
module FakeRedis
  class Redis
    class Client
      attr_accessor :host, :port, :db, :path, :password, :logger, :reconnect
      def initialize(options = {})
        @path      = options[:path]
        @host      = options[:host] || "127.0.0.1"
        @port      = (options[:port] || 6379).to_i
        @password  = options[:password]
        @db        = (options[:db] || 0).to_i
        @logger    = options[:logger]
        @reconnect = true
      end

      def connect
        self
      end

      def connected?
        true
      end

      def method_missing(command, *args, &block)
        true
      end
    end

    def self.connect(options = {})
      new(options)
    end

    def initialize(options = {})
      @data = {}
      @expires = {}
      @client = Client.new
    end

    def client
      @client
    end
  end
end

require 'set'

require "fakeredis/connection"
require "fakeredis/keys"
require "fakeredis/strings"
require "fakeredis/hashes"
require "fakeredis/lists"
require "fakeredis/sets"
#require "fakeredis/sorted_sets"
require "fakeredis/transactions"
require "fakeredis/server"
