require 'redis/connection/registry'
require 'redis/connection/command_helper'

class Redis
  module Connection
    class Memory
      # Represents a normal hash with some additional expiration information
      # associated with each key
      class ExpiringHash < Hash
        attr_reader :expires

        def initialize(*)
          super
          @expires = {}
        end

        def [](key)
          delete(key) if expired?(key)
          super
        end

        def []=(key, val)
          expire(key)
          super
        end

        def delete(key)
          expire(key)
          super
        end

        def expire(key)
          expires.delete(key)
        end

        def expired?(key)
          expires.include?(key) && expires[key] < Time.now
        end

        def key?(key)
          delete(key) if expired?(key)
          super
        end

        def values_at(*keys)
          keys.each {|key| delete(key) if expired?(key)}
          super
        end

        def keys
          super.select do |key|
            if expired?(key)
              delete(key)
              false
            else
              true
            end
          end
        end
      end

      include Redis::Connection::CommandHelper

      def initialize
        @data = ExpiringHash.new
        @connected = false
        @replies = []
        @buffer = nil
      end

      def connected?
        @connected
      end

      def connect(host, port, timeout)
        @connected = true
      end

      def connect_unix(path, timeout)
        @connected = true
      end

      def disconnect
        @connected = false
        nil
      end

      def timeout=(usecs)
      end

      def write(command)
        method = command.shift
        reply = send(method, *command)

        if reply == true
          reply = 1
        elsif reply == false
          reply = 0
        end

        @replies << reply
        @buffer << reply if @buffer && method != :multi
        nil
      end

      def read
        @replies.shift
      end

      # NOT IMPLEMENTED:
      # * blpop
      # * brpop
      # * brpoplpush
      # * discard
      # * mapped_hmset
      # * mapped_hmget
      # * mapped_mset
      # * mapped_msetnx
      # * move
      # * subscribe
      # * psubscribe
      # * publish
      # * substr
      # * unwatch
      # * watch
      # * zadd
      # * zcard
      # * zcount
      # * zincrby
      # * zinterstore
      # * zrange
      # * zrangescore
      # * zrank
      # * zrem
      # * zremrangebyrank
      # * zremrangebyscore
      # * zrevrange
      # * zrevrangebyscore
      # * zscore
      # * zunionstore
      def flushdb
        @data = ExpiringHash.new
      end

      def flushall
        flushdb
      end

      def auth(password)
        "OK"
      end

      def select(index) ; end

      def info
        {
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
      end

      def monitor; end

      def save; end

      def bgsave ; end

      def bgreriteaof ; end

      def get(key)
        @data[key]
      end

      def getbit(key, offset)
        return unless @data[key]
        @data[key].unpack('B8')[0].split("")[offset]
      end

      def getrange(key, start, ending)
        return unless @data[key]
        @data[key][start..ending]
      end

      def getset(key, value)
        old_value = @data[key]
        @data[key] = value
        return old_value
      end

      def mget(*keys)
        @data.values_at(*keys)
      end

      def append(key, value)
        @data[key] = (@data[key] || "")
        @data[key] = @data[key] + value.to_s
      end

      def strlen(key)
        return unless @data[key]
        @data[key].size
      end

      def hgetall(key)
        case hash = @data[key]
          when nil then {}
          when Hash then hash
          else fail "Not a hash"
        end
      end

      def hget(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key][field]
      end

      def hdel(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key].delete(field)
      end

      def hkeys(key)
        case hash = @data[key]
          when nil then []
          when Hash then hash.keys
          else fail "Not a hash"
        end
      end

      def keys(pattern = "*")
        regexp = Regexp.new(pattern.split("*").map { |r| Regexp.escape(r) }.join(".*"))
        @data.keys.select { |key| key =~ regexp }
      end

      def randomkey
        @data.keys[rand(dbsize)]
      end

      def echo(string)
        string
      end

      def ping
        "PONG"
      end

      def lastsave
        Time.now.to_i
      end

      def dbsize
        @data.keys.count
      end

      def exists(key)
        @data.key?(key)
      end

      def llen(key)
        @data[key] ||= []
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].size
      end

      def lrange(key, startidx, endidx)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key][startidx..endidx]
      end

      def ltrim(key, start, stop)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        @data[key] = @data[key][start..stop]
      end

      def lindex(key, index)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        @data[key][index]
      end

      def linsert(key, where, pivot, value)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        index = @data[key].index(pivot)
        case where
          when :before then @data[key].insert(index, value)
          when :after  then @data[key].insert(index + 1, value)
          else raise ArgumentError.new
        end
      end

      def lset(key, index, value)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        raise RuntimeError unless index < @data[key].size
        @data[key][index] = value
      end

      def lrem(key, count, value)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        old_size = @data[key].size
        if count == 0
          @data[key].delete(value)
          old_size - @data[key].size
        else
          array = count > 0 ? @data[key].dup : @data[key].reverse
          count.abs.times{ array.delete_at(array.index(value) || array.length) }
          @data[key] = count > 0 ? array.dup : array.reverse
          old_size - @data[key].size
        end
      end

      def rpush(key, value)
        @data[key] ||= []
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].push(value)
      end

      def rpushx(key, value)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        rpush(key, value)
      end

      def lpush(key, value)
        @data[key] ||= []
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key] = [value] + @data[key]
        @data[key].size
      end

      def lpushx(key, value)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        lpush(key, value)
      end

      def rpop(key)
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].pop
      end

      def rpoplpush(key1, key2)
        fail "Not a list" unless @data[key1].is_a?(Array)
        elem = @data[key1].pop
        lpush(key2, elem)
      end

      def lpop(key)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].delete_at(0)
      end

      def smembers(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then []
          when Set then set.to_a.reverse
        end
      end

      def sismember(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then false
          when Set then set.include?(value.to_s)
        end
      end

      def sadd(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then @data[key] = Set.new([value.to_s])
          when Set then set.add(value.to_s)
        end
      end

      def srem(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then return
          when Set then set.delete(value.to_s)
        end
      end

      def smove(source, destination, value)
        fail_unless_set(destination)
        if elem = self.srem(source, value)
          self.sadd(destination, value)
        end
      end

      def spop(key)
        fail_unless_set(key)
        elem = srandmember(key)
        srem(key, elem)
        elem
      end

      def scard(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then 0
          when Set then set.size
        end
      end

      def sinter(*keys)
        keys.each { |k| fail_unless_set(k) }
        return Set.new if keys.any? { |k| @data[k].nil? }
        keys = keys.map { |k| @data[k] || Set.new }
        keys.inject do |set, key|
          set & key
        end.to_a
      end

      def sinterstore(destination, *keys)
        fail_unless_set(destination)
        result = sinter(*keys)
        @data[destination] = Set.new(result)
      end

      def sunion(*keys)
        keys.each { |k| fail_unless_set(k) }
        keys = keys.map { |k| @data[k] || Set.new }
        keys.inject(Set.new) do |set, key|
          set | key
        end.to_a
      end

      def sunionstore(destination, *keys)
        fail_unless_set(destination)
        result = sunion(*keys)
        @data[destination] = Set.new(result)
      end

      def sdiff(key1, *keys)
        [key1, *keys].each { |k| fail_unless_set(k) }
        keys = keys.map { |k| @data[k] || Set.new }
        keys.inject(@data[key1]) do |memo, set|
          memo - set
        end.to_a
      end

      def sdiffstore(destination, key1, *keys)
        fail_unless_set(destination)
        result = sdiff(key1, *keys)
        @data[destination] = Set.new(result)
      end

      def srandmember(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then nil
          when Set then set.to_a[rand(set.size)]
        end
      end

      def del(*keys)
        old_count = @data.keys.size
        keys.flatten.each do |key|
          @data.delete(key)
        end
        deleted_count = old_count - @data.keys.size
      end

      def setnx(key, value)
        if exists(key)
          false
        else
          set(key, value)
          true
        end
      end

      def rename(key, new_key)
        return unless @data[key]
        @data[new_key] = @data[key]
        @data.expires[new_key] = @data.expires[key] if @data.expires.include?(key)
        @data.delete(key)
      end

      def renamenx(key, new_key)
        if exists(new_key)
          false
        else
          rename(key, new_key)
          true
        end
      end

      def expire(key, ttl)
        return unless @data[key]
        @data.expires[key] = Time.now + ttl
        true
      end

      def ttl(key)
        if @data.expires.include?(key) && (ttl = @data.expires[key].to_i - Time.now.to_i) > 0
          ttl
        else
          -1
        end
      end

      def expireat(key, timestamp)
        @data.expires[key] = Time.at(timestamp)
        true
      end

      def persist(key)
        @data.expires.delete(key)
      end

      def hset(key, field, value)
        case hash = @data[key]
          when nil then @data[key] = { field => value.to_s }
          when Hash then hash[field] = value.to_s
          else fail "Not a hash"
        end
      end

      def hsetnx(key, field, value)
        return if (@data[key][field] rescue false)
        hset(key, field, value)
      end

      def hmset(key, *fields)
        @data[key] ||= {}
        fail "Not a hash" unless @data[key].is_a?(Hash)
        fields.each_slice(2) do |field|
          @data[key][field[0].to_s] = field[1].to_s
        end
      end

      def hmget(key, *fields)
        values = []
        fields.each do |field|
          case hash = @data[key]
            when nil then values << nil
            when Hash then values << hash[field]
            else fail "Not a hash"
          end
        end
        values
      end

      def hlen(key)
        case hash = @data[key]
          when nil then 0
          when Hash then hash.size
          else fail "Not a hash"
        end
      end

      def hvals(key)
        case hash = @data[key]
          when nil then []
          when Hash then hash.values
          else fail "Not a hash"
        end
      end

      def hincrby(key, field, increment)
        case hash = @data[key]
          when nil then @data[key] = { field => value.to_s }
          when Hash then hash[field] = (hash[field].to_i + increment.to_i).to_s
          else fail "Not a hash"
        end
      end

      def hexists(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key].key?(field)
      end

      def sync ; end

      def [](key)
        get(key)
      end

      def []=(key, value)
        set(key, value)
      end

      def set(key, value)
        @data[key] = value.to_s
        "OK"
      end

      def setbit(key, offset, bit)
        return unless @data[key]
        old_val = @data[key].unpack('B*')[0].split("")
        old_val[offset] = bit.to_s
        new_val = ""
        old_val.each_slice(8){|b| new_val = new_val + b.join("").to_i(2).chr }
        @data[key] = new_val
      end

      def setex(key, seconds, value)
        @data[key] = value
        expire(key, seconds)
      end

      def setrange(key, offset, value)
        return unless @data[key]
        s = @data[key][offset,value.size]
        @data[key][s] = value
      end

      def mset(*pairs)
        pairs.each_slice(2) do |pair|
          @data[pair[0].to_s] = pair[1].to_s
        end
        "OK"
      end

      def msetnx(*pairs)
        keys = []
        pairs.each_with_index{|item, index| keys << item.to_s if index % 2 == 0}
        return if keys.any?{|key| @data.key?(key) }
        mset(*pairs)
        true
      end

      def mapped_mget(*keys)
        reply = mget(*keys)
        Hash[*keys.zip(reply).flatten]
      end

      def sort(key)
        # TODO: Impleent
      end

      def incr(key)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i + 1).to_s
      end

      def incrby(key, by)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i + by.to_i).to_s
      end

      def decr(key)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i - 1).to_s
      end

      def decrby(key, by)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i - by.to_i).to_s
      end

      def type(key)
        case value = @data[key]
          when nil then "none"
          when String then "string"
          when Hash then "hash"
          when Array then "list"
          when Set then "set"
        end
      end

      def quit ; end

      def shutdown; end

      def slaveof(host, port) ; end

      def exec
        buffer = @buffer
        @buffer = nil
        buffer
      end

      def multi
        @buffer = []
        yield if block_given?
        "OK"
      end

      private
        def is_a_set?(key)
          @data[key].is_a?(Set) || @data[key].nil?
        end

        def fail_unless_set(key)
          fail "Not a set" unless is_a_set?(key)
        end
    end
  end
end

Redis::Connection.drivers << Redis::Connection::Memory
