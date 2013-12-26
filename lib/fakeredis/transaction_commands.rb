module FakeRedis
  module TransactionCommands
    REDIS_COMMANDS = [
      :append, :auth, :bgrewriteaof, :bgsave, :bitcount, :bitop, :blpop, :brpop,
      :brpoplpush, :dbsize, :decr, :decrby, :del, :discard, :dump, :echo, :eval,
      :evalsha, :exec, :exists, :expire, :expireat, :flushall, :flushdb, :get,
      :getbit, :getrange, :getset, :hdel, :hexists, :hget, :hgetall, :hincrby,
      :hincrbyfloat, :hkeys, :hlen, :hmget, :hmset, :hscan, :hset, :hsetnx,
      :hvals, :incr, :incrby, :incrbyfloat, :info, :keys, :lastsave, :lindex,
      :linsert, :llen, :lpop, :lpush, :lpushx, :lrange, :lrem, :lset, :ltrim,
      :mget, :migrate, :monitor, :move, :mset, :msetnx, :multi, :object,
      :persist, :pexpire, :pexpireat, :ping, :psetex, :psubscribe, :pttl,
      :publish, :pubsub, :punsubscribe, :quit, :randomkey, :rename, :renamenx,
      :restore, :rpop, :rpoplpush, :rpush, :rpushx, :sadd, :save, :scan,
      :scard, :sdiff, :sdiffstore, :select, :set, :setbit, :setex, :setnx,
      :setrange, :shutdown, :sinter, :sinterstore, :sismember, :slaveof,
      :slowlog, :smembers, :smove, :sort, :spop, :srandmember, :srem, :sscan,
      :strlen, :subscribe, :sunion, :sunionstore, :sync, :time, :ttl, :type,
      :unsubscribe, :unwatch, :watch, :zadd, :zcard, :zcount, :zincrby,
      :zinterstore, :zrange, :zrangebyscore, :zrank, :zrem, :zremrangebyrank,
      :zremrangebyscore, :zrevrange, :zrevrangebyscore, :zrevrank, :zscan,
      :zscore, :zunionstore
    ]

    def self.included(klass)
      klass.class_eval do
        def self.queued_commands
          @queued_commands ||= Hash.new {|h,k| h[k] = [] }
        end

        def self.in_multi
          @in_multi ||= Hash.new{|h,k| h[k] = false}
        end

        def queued_commands
          self.class.queued_commands[database_instance_key]
        end

        def queued_commands=(cmds)
          self.class.queued_commands[database_instance_key] = cmds
        end

        def in_multi
          self.class.in_multi[database_instance_key]
        end

        def in_multi=(multi_state)
          self.class.in_multi[database_instance_key] = multi_state
        end
      end
    end

    def discard
      unless in_multi
        raise Redis::CommandError, "ERR DISCARD without MULTI"
      end

      revert_alias_redis_commands!

      self.in_multi = false
      self.queued_commands = []
      'OK'
    end

    def exec
      unless in_multi
        raise Redis::CommandError, "ERR EXEC without MULTI"
      end

      revert_alias_redis_commands!

      responses  = queued_commands.map do |cmd|
        begin
          send(*cmd)
        rescue => e
          e
        end
      end

      self.queued_commands = [] # reset queued_commands
      self.in_multi = false     # reset in_multi state

      responses
    end

    def multi
      if in_multi
        raise Redis::CommandError, "ERR MULTI calls can not be nested"
      end

      self.in_multi = true
      alias_redis_commands!

      yield(self) if block_given?

      "OK"
    end

    def watch(_)
      "OK"
    end

    def unwatch
      "OK"
    end

    private

    # Private: alias redis commands, and redefine them.
    #
    # Example:
    #   Original `set` method will be aliased as `real_set` method,
    #   and `set` method will just put command call to queued_commands.
    #
    def alias_redis_commands!
      self.class.class_eval {
        all_instance_methods = self.instance_methods(false).map(&:to_sym)
        REDIS_COMMANDS.each { |m|
          next unless all_instance_methods.include? m

          alias_method "real_#{m}".to_sym, m
          define_method m do |*args|
            queued_commands << [m, *args]
            'QUEUED'
          end
        }
      }
    end

    # Private: revert `alias_redis_commands!`
    def revert_alias_redis_commands!
      self.class.class_eval {
        all_instance_methods = self.instance_methods(false).map(&:to_sym)
        REDIS_COMMANDS.each { |m|
          next unless all_instance_methods.include? m

          alias_method m, "real_#{m}".to_sym
          undef_method "real_#{m}".to_sym
        }
      }
    end
  end
end
