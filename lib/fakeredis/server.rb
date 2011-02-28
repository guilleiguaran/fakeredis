module FakeRedis
  class Redis
    module ServerMethods

      def bgreriteaof ; end

      def bgsave ; end

      def config_get(param) ; end

      def config_set(param, value) ; end

      def config_resetstat ; end

      def dbsize
        @data.keys.count
      end

      def debug_object(key)
        return @data[key].inspect
      end

      def flushdb
        @data = {}
        @expires = {}
      end

      alias flushall flushdb

      def info
        server_info = {
          "redis_version" => "0.07",
          "connected_clients" => "1",
          "connected_slaves" => "0",
          "used_memory" => "3187",
          "changes_since_last_save" => "0",
          "last_save_time" => "1237655729",
          "total_connections_received" => "1",
          "total_commands_processed" => "1",
          "uptime_in_seconds" => "36000",
          "uptime_in_days" => 0
        }
        return server_info
      end

      def lastsave
        Time.now.to_i
      end

      def monitor ; end

      def save ; end

      def shutdown ; end

      def slaveof(host, port) ; end

      def sync ; end

      alias reset flushdb
    end

    include ServerMethods
  end
end
