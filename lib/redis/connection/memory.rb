require 'set'
require 'redis/connection/registry'
require 'redis/connection/command_helper'

require 'redis/commands/connection'
require 'redis/commands/hashes'
require 'redis/commands/keys'
require 'redis/commands/lists'
require 'redis/commands/server'
require 'redis/commands/sets'
require 'redis/commands/sorted_sets'
require 'redis/commands/strings'
require 'redis/commands/transactions'

require 'fakeredis/expiring_hash'

class Redis
  module Connection
    class Memory      
      #FAKEREDIS
      include FakeRedis

      # CONNECTION
      include Redis::Connection::CommandHelper
      
      # COMMANDS
      include Redis::Commands::Connection
      include Redis::Commands::Hashes
      include Redis::Commands::Keys
      include Redis::Commands::Lists
      include Redis::Commands::Server
      include Redis::Commands::Sets
      include Redis::Commands::SortedSets
      include Redis::Commands::Strings
      include Redis::Commands::Transactions      

      attr_accessor :buffer, :options

      # Tracks all databases for all instances across the current process.
      # We have to be able to handle two clients with the same host/port accessing
      # different databases at once without overwriting each other. So we store our
      # "data" outside the client instances, in this class level method.
      # Client instances access it with a key made up of their host/port, and then select
      # which DB out of the array of them they want. Allows the access we need.
      def self.databases
        @databases ||= Hash.new {|h,k| h[k] = [] }
      end

      # Used for resetting everything in specs
      def self.reset_all_databases
        @databases = nil
      end

      def self.connect(options = {})
        new(options)
      end

      def initialize(options = {})
        self.options = options
      end

      def database_id
        @database_id ||= 0
      end
      attr_writer :database_id

      def database_instance_key
        [options[:host], options[:port]].hash
      end

      def databases
        self.class.databases[database_instance_key]
      end

      def find_database id=database_id
        databases[id] ||= ExpiringHash.new
      end

      def data
        find_database
      end

      def replies
        @replies ||= []
      end
      attr_writer :replies

      def connected?
        true
      end

      def connect_unix(path, timeout)
      end

      def disconnect
      end

      def timeout=(usecs)
      end

      def write(command)
        meffod = command.shift.to_s.downcase.to_sym
        if respond_to?(meffod)
          reply = send(meffod, *command)
        else
          raise Redis::CommandError, "ERR unknown command '#{meffod}'"
        end

        if reply == true
          reply = 1
        elsif reply == false
          reply = 0
        end

        replies << reply
        buffer << reply if buffer && meffod != :multi
        nil
      end

      def read
        replies.shift
      end

      def [](key)
        get(key)
      end

      def []=(key, value)
        set(key, value)
      end      

      private

        def raise_argument_error command
          raise Redis::CommandError, "ERR wrong number of arguments for '#{command}' command"
        end

        def raise_syntax_error
          raise Redis::CommandError, "ERR syntax error"
        end

        def remove_key_for_empty_collection(key)
          del(key) if data[key] && data[key].empty?
        end

        def data_type_check(key, klass)
          if data[key] && !data[key].is_a?(klass)
            warn "Operation against a key holding the wrong kind of value: Expected #{klass} at #{key}."
            raise Redis::CommandError.new("ERR Operation against a key holding the wrong kind of value")
          end
        end

        def get_limit(opts, vals)
          index = opts.index('LIMIT')

          if index
            offset = opts[index + 1]

            count = opts[index + 2]
            count = vals.size if count < 0

            [offset, count]
          end
        end

        def mapped_param? param
          param.size == 1 && param[0].is_a?(Array)
        end
    end
  end

end

Redis::Connection.drivers << Redis::Connection::Memory
