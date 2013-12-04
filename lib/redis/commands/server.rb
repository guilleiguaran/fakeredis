class Redis
	module Commands
		# Class related to server commands
		#
		# Unimplemented commands:
		#
		# => CONFIG GET
		# => DEBUG SEGFAULT
		# => CONFIG REWRITE
		# => CLIENT KIL
		# => CONFIG SET
		# => CLIENT LIST
		# => CONFIG RESETSTAT
		# => SLOWLOG
		# => CLIENT GETNAME
		# => CLIENT SETNAME
		# => DEBUG OBJECT
		# => TIME
		# 
		# Implemented fake commands:
		#
		# => BGREWRITEAOF
		# => MONITOR
		# => SAVE
		# => BGSAVE
		# => FLUSHALL
		# => FLUSHDB
		# => SHUTDOWN
		# => SLAVEOF
		# => INFO
		# => LASTSAVE
		# => SYNC
		# => DBSIZE
		module Server

			def bgrewriteaof
				'OK'
			end

      def monitor; end

      def save; end

      def bgsave ; end

      def flushdb
        databases.delete_at(database_id)
        "OK"
      end

      def flushall
        self.class.databases[database_instance_key] = []
        "OK"
      end

      def shutdown; end

      def slaveof(host, port) ; end

      def info
        {
          "redis_version" => "2.6.16",
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
      end

      def lastsave
        Time.now.to_i
      end

      def dbsize
        data.keys.count
      end

      def sync ; end

		end
	end
end