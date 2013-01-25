require 'set'
require 'redis/connection/registry'
require 'redis/connection/command_helper'
require "fakeredis/expiring_hash"
require "fakeredis/zset"

class Redis
  module Connection
    class Memory
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
        meffod = command.shift
        if respond_to?(meffod)
          reply = send(meffod, *command)
        else
          raise RuntimeError, "ERR unknown command '#{meffod}'"
        end

        if reply == true
          reply = 1
        elsif reply == false
          reply = 0
        end

        @replies << reply
        @buffer << reply if @buffer && meffod != :multi
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
      # * move
      # * subscribe
      # * psubscribe
      # * publish
      # * zremrangebyrank
      # * zunionstore
      def flushdb
        @data = ExpiringHash.new
        "OK"
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
        data_type_check(key, String)
        @data[key]
      end

      def getbit(key, offset)
        return unless @data[key]
        @data[key].unpack('B*')[0].split("")[offset].to_i
      end

      def getrange(key, start, ending)
        return unless @data[key]
        @data[key][start..ending]
      end
      alias :substr :getrange

      def getset(key, value)
        data_type_check(key, String)
        @data[key].tap do
          set(key, value)
        end
      end

      def mget(*keys)
        raise RuntimeError, "ERR wrong number of arguments for 'mget' command" if keys.empty?
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
        data_type_check(key, Hash)
        @data[key] || {}
      end

      def hget(key, field)
        data_type_check(key, Hash)
        @data[key] && @data[key][field.to_s]
      end

      def hdel(key, field)
        data_type_check(key, Hash)
        @data[key] && @data[key].delete(field)
        remove_key_for_empty_collection(key)
      end

      def hkeys(key)
        data_type_check(key, Hash)
        return [] if @data[key].nil?
        @data[key].keys
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
        data_type_check(key, Array)
        return 0 unless @data[key]
        @data[key].size
      end

      def lrange(key, startidx, endidx)
        data_type_check(key, Array)
        @data[key] && @data[key][startidx..endidx] || []
      end

      def ltrim(key, start, stop)
        data_type_check(key, Array)
        return unless @data[key]
        @data[key] = @data[key][start..stop]
      end

      def lindex(key, index)
        data_type_check(key, Array)
        @data[key] && @data[key][index]
      end

      def linsert(key, where, pivot, value)
        data_type_check(key, Array)
        return unless @data[key]
        index = @data[key].index(pivot)
        case where
          when :before then @data[key].insert(index, value)
          when :after  then @data[key].insert(index + 1, value)
          else raise ArgumentError
        end
      end

      def lset(key, index, value)
        data_type_check(key, Array)
        return unless @data[key]
        raise RuntimeError, "ERR index out of range" if index >= @data[key].size
        @data[key][index] = value
      end

      def lrem(key, count, value)
        data_type_check(key, Array)
        return unless @data[key]
        old_size = @data[key].size
        diff =
          if count == 0
            @data[key].delete(value)
            old_size - @data[key].size
          else
            array = count > 0 ? @data[key].dup : @data[key].reverse
            count.abs.times{ array.delete_at(array.index(value) || array.length) }
            @data[key] = count > 0 ? array.dup : array.reverse
            old_size - @data[key].size
          end
        remove_key_for_empty_collection(key)
        diff
      end

      def rpush(key, value)
        data_type_check(key, Array)
        @data[key] ||= []
        @data[key].push(value.to_s)
        @data[key].size
      end

      def rpushx(key, value)
        data_type_check(key, Array)
        return unless @data[key]
        rpush(key, value)
      end

      def lpush(key, value)
        data_type_check(key, Array)
        @data[key] ||= []
        @data[key].unshift(value.to_s)
        @data[key].size
      end

      def lpushx(key, value)
        data_type_check(key, Array)
        return unless @data[key]
        lpush(key, value)
      end

      def rpop(key)
        data_type_check(key, Array)
        return unless @data[key]
        @data[key].pop
      end

      def rpoplpush(key1, key2)
        data_type_check(key1, Array)
        rpop(key1).tap do |elem|
          lpush(key2, elem)
        end
      end

      def lpop(key)
        data_type_check(key, Array)
        return unless @data[key]
        @data[key].shift
      end

      def smembers(key)
        data_type_check(key, ::Set)
        return [] unless @data[key]
        @data[key].to_a.reverse
      end

      def sismember(key, value)
        data_type_check(key, ::Set)
        return false unless @data[key]
        @data[key].include?(value.to_s)
      end

      def sadd(key, value)
        data_type_check(key, ::Set)
        if @data[key]
          !!@data[key].add?(value.to_s)
        else
          @data[key] = ::Set.new([value.to_s])
          true
        end
      end

      def srem(key, value)
        data_type_check(key, ::Set)
        deleted = !!(@data[key] && @data[key].delete?(value.to_s))
        remove_key_for_empty_collection(key)
        deleted
      end

      def smove(source, destination, value)
        data_type_check(destination, ::Set)
        result = self.srem(source, value)
        self.sadd(destination, value) if result
        result
      end

      def spop(key)
        data_type_check(key, ::Set)
        elem = srandmember(key)
        srem(key, elem)
        elem
      end

      def scard(key)
        data_type_check(key, ::Set)
        return 0 unless @data[key]
        @data[key].size
      end

      def sinter(*keys)
        keys.each { |k| data_type_check(k, ::Set) }
        return ::Set.new if keys.any? { |k| @data[k].nil? }
        keys = keys.map { |k| @data[k] || ::Set.new }
        keys.inject do |set, key|
          set & key
        end.to_a
      end

      def sinterstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sinter(*keys)
        @data[destination] = ::Set.new(result)
      end

      def sunion(*keys)
        keys.each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| @data[k] || ::Set.new }
        keys.inject(::Set.new) do |set, key|
          set | key
        end.to_a
      end

      def sunionstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sunion(*keys)
        @data[destination] = ::Set.new(result)
      end

      def sdiff(key1, *keys)
        [key1, *keys].each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| @data[k] || ::Set.new }
        keys.inject(@data[key1]) do |memo, set|
          memo - set
        end.to_a
      end

      def sdiffstore(destination, key1, *keys)
        data_type_check(destination, ::Set)
        result = sdiff(key1, *keys)
        @data[destination] = ::Set.new(result)
      end

      def srandmember(key)
        data_type_check(key, ::Set)
        return nil unless @data[key]
        @data[key].to_a[rand(@data[key].size)]
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
        !!@data.expires.delete(key)
      end

      def hset(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        if @data[key]
          result = !@data[key].include?(field)
          @data[key][field] = value.to_s
          result
        else
          @data[key] = { field => value.to_s }
          true
        end
      end

      def hsetnx(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        return false if @data[key] && @data[key][field]
        hset(key, field, value)
      end

      def hmset(key, *fields)
        # mapped_hmset gives us [[:k1, "v1", :k2, "v2"]] for `fields`. Fix that.
        fields = fields[0] if fields.size == 1 && fields[0].is_a?(Array)
        fields = fields[0] if mapped_param?(fields)
        raise RuntimeError, "ERR wrong number of arguments for HMSET" if fields.size > 2 && fields.size.odd?
        raise RuntimeError, "ERR wrong number of arguments for 'hmset' command" if fields.empty? || fields.size.odd?
        data_type_check(key, Hash)
        @data[key] ||= {}
        fields.each_slice(2) do |field|
          @data[key][field[0].to_s] = field[1].to_s
        end
      end

      def hmget(key, *fields)
        raise RuntimeError, "ERR wrong number of arguments for 'hmget' command" if fields.empty?
        data_type_check(key, Hash)
        values = []
        fields.map do |field|
          field = field.to_s
          if @data[key]
            @data[key][field]
          else
            nil
          end
        end
      end

      def hlen(key)
        data_type_check(key, Hash)
        return 0 unless @data[key]
        @data[key].size
      end

      def hvals(key)
        data_type_check(key, Hash)
        return [] unless @data[key]
        @data[key].values
      end

      def hincrby(key, field, increment)
        data_type_check(key, Hash)
        if @data[key]
          @data[key][field] = (@data[key][field.to_s].to_i + increment.to_i).to_s
        else
          @data[key] = { field => increment.to_s }
        end
        @data[key][field].to_i
      end

      def hexists(key, field)
        data_type_check(key, Hash)
        return false unless @data[key]
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
        old_val = @data[key] ? @data[key].unpack('B*')[0].split("") : []
        size_increment = [((offset/8)+1)*8-old_val.length, 0].max
        old_val += Array.new(size_increment).map{"0"}
        original_val = old_val[offset]
        old_val[offset] = bit.to_s
        new_val = ""
        old_val.each_slice(8){|b| new_val = new_val + b.join("").to_i(2).chr }
        @data[key] = new_val
        original_val
      end

      def setex(key, seconds, value)
        @data[key] = value.to_s
        expire(key, seconds)
      end

      def setrange(key, offset, value)
        return unless @data[key]
        s = @data[key][offset,value.size]
        @data[key][s] = value
      end

      def mset(*pairs)
        # Handle pairs for mapped_mset command
        pairs = pairs[0] if mapped_param?(pairs)
        pairs.each_slice(2) do |pair|
          @data[pair[0].to_s] = pair[1].to_s
        end
        "OK"
      end

      def msetnx(*pairs)
        # Handle pairs for mapped_mset command
        pairs = pairs[0] if mapped_param?(pairs)
        keys = []
        pairs.each_with_index{|item, index| keys << item.to_s if index % 2 == 0}
        return false if keys.any? {|key| @data.key?(key) }
        mset(*pairs)
        true
      end

      def sort(key)
        # TODO: Implement
      end

      def incr(key)
        @data.merge!({ key => (@data[key].to_i + 1).to_s || "1"})
        @data[key].to_i
      end

      def incrby(key, by)
        @data.merge!({ key => (@data[key].to_i + by.to_i).to_s || by })
        @data[key].to_i
      end

      def decr(key)
        @data.merge!({ key => (@data[key].to_i - 1).to_s || "-1"})
        @data[key].to_i
      end

      def decrby(key, by)
        @data.merge!({ key => ((@data[key].to_i - by.to_i) || (by.to_i * -1)).to_s })
        @data[key].to_i
      end

      def type(key)
        case value = @data[key]
          when nil then "none"
          when String then "string"
          when Hash then "hash"
          when Array then "list"
          when ::Set then "set"
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

      def watch(_)
        "OK"
      end

      def unwatch
        "OK"
      end

      def zadd(key, score, value)
        data_type_check(key, ZSet)
        @data[key] ||= ZSet.new
        exists = @data[key].key?(value.to_s)
        score = "inf" if score == "+inf"
        @data[key][value.to_s] = score
        !exists
      end

      def zrem(key, value)
        data_type_check(key, ZSet)
        exists = false
        exists = @data[key].delete(value.to_s) if @data[key]
        remove_key_for_empty_collection(key)
        !!exists
      end

      def zcard(key)
        data_type_check(key, ZSet)
        @data[key] ? @data[key].size : 0
      end

      def zscore(key, value)
        data_type_check(key, ZSet)
        @data[key] && @data[key][value.to_s].to_s
      end

      def zcount(key, min, max)
        data_type_check(key, ZSet)
        return 0 unless @data[key]
        zrange_select_by_score(key, min, max).size
      end

      def zincrby(key, num, value)
        data_type_check(key, ZSet)
        @data[key] ||= ZSet.new
        @data[key][value.to_s] ||= 0
        if %w(+inf -inf).include?(num)
          num = "inf" if num == "+inf"
          @data[key][value.to_s] = num
        elsif ! %w(+inf -inf).include?(@data[key][value.to_s])
          @data[key][value.to_s] += num
        end
        @data[key][value.to_s].to_s
      end

      def zrank(key, value)
        data_type_check(key, ZSet)
        @data[key].keys.sort_by {|k| @data[key][k] }.index(value.to_s)
      end

      def zrevrank(key, value)
        data_type_check(key, ZSet)
        @data[key].keys.sort_by {|k| -@data[key][k] }.index(value.to_s)
      end

      def zrange(key, start, stop, with_scores = nil)
        data_type_check(key, ZSet)
        return [] unless @data[key]

        if with_scores
          @data[key].sort_by {|_,v| v }
        else
          @data[key].keys.sort_by {|k| @data[key][k] }
        end[start..stop].flatten.map(&:to_s)
      end

      def zrevrange(key, start, stop, with_scores = nil)
        data_type_check(key, ZSet)
        return [] unless @data[key]

        if with_scores
          @data[key].sort_by {|_,v| -v }
        else
          @data[key].keys.sort_by {|k| -@data[key][k] }
        end[start..stop].flatten.map(&:to_s)
      end

      def zrangebyscore(key, min, max, *opts)
        data_type_check(key, ZSet)
        return [] unless @data[key]

        range = zrange_select_by_score(key, min, max)
        vals = if opts.include?('WITHSCORES')
          range.sort_by {|_,v| v }
        else
          range.keys.sort_by {|k| range[k] }
        end

        limit = get_limit(opts, vals)
        vals = vals[*limit] if limit

        vals.flatten.map(&:to_s)
      end

      def zrevrangebyscore(key, max, min, *opts)
        data_type_check(key, ZSet)
        return [] unless @data[key]

        range = zrange_select_by_score(key, min, max)
        vals = if opts.include?('WITHSCORES')
          range.sort_by {|_,v| -v }
        else
          range.keys.sort_by {|k| -range[k] }
        end

        limit = get_limit(opts, vals)
        vals = vals[*limit] if limit

        vals.flatten.map(&:to_s)
      end

      def zremrangebyscore(key, min, max)
        data_type_check(key, ZSet)
        return 0 unless @data[key]

        range = zrange_select_by_score(key, min, max)
        range.each {|k,_| @data[key].delete(k) }
        range.size
      end

      def weights_aggregate_arguments_handler
        Class.new do
          attr_accessor :type, :number_of_keys, :keys
          attr_reader :aggregate
          attr_writer :weights

          def initialize args
            self.number_of_keys = args.shift
            self.keys = args.shift(number_of_keys)

            args.inject(self) {|handler, item| handler.handle(item) }

            self.weights = Array.new(number_of_keys) { 1 } if self.weights.empty?
            self.aggregate ||= :sum

            raise(Redis::CommandError, "ERR syntax error") unless weights.size == number_of_keys
          end

          def weights
            @weights ||= []
          end

          # Only allows assigning a variable *once*
          def aggregate=(str)
            if (defined?(@aggregate) && @aggregate) || ![:min, :max, :sum].include?(str.downcase.to_sym)
              raise(Redis::CommandError, "ERR syntax error")
            end
            @aggregate = str
          end

          def handle(item)
            case item
            when "WEIGHTS"
              self.type = :weights
            when "AGGREGATE"
              self.type = :aggregate
            when nil
              # This should never be called, raise a syntax error if we manage to hit it
              raise(Redis::CommandError, "ERR syntax error")
            else
              send "handle_#{type}", item
            end
            self
          end

          def handle_weights(item)
            self.weights << item
          end

          def handle_aggregate(item)
            self.aggregate = item
          end

          def inject_block
            lambda do |handler, item|
              handler.handle(item)
            end
          end
        end
      end

      def zinterstore(out, _, *keys)
        data_type_check(out, ZSet)

        hashes = keys.map do |src|
          case @data[src]
          when ::Set
            # Every value has a score of 1
            Hash[@data[src].map {|k,v| [k, 1]}]
          when Hash
            @data[src]
          else
            {}
          end
        end

        @data[out] = ZSet.new
        values = hashes.inject([]) {|r, h| r.empty? ? h.keys : r & h.keys }
        values.each do |value|
          @data[out][value] = hashes.inject(0) {|n, h| n + h[value].to_i }
        end

        @data[out].size
      end

      def zremrangebyrank(key, start, stop)
        sorted_elements = @data[key].sort { |(v_a, r_a), (v_b, r_b)| r_a <=> r_b }
        start = sorted_elements.length if start > sorted_elements.length
        elements_to_delete = sorted_elements[start..stop]
        elements_to_delete.each { |elem, rank| @data[key].delete(elem) }
        elements_to_delete.size
      end

      private

        def zrange_select_by_score(key, min, max)
          @data[key].reject {|_,v| v < min || v > max }
        end

        def remove_key_for_empty_collection(key)
          del(key) if @data[key] && @data[key].empty?
        end

        def data_type_check(key, klass)
          if @data[key] && !@data[key].is_a?(klass)
            warn "Operation against a key holding the wrong kind of value: Expected #{klass} at #{key}."
            raise RuntimeError.new("ERR Operation against a key holding the wrong kind of value")
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
