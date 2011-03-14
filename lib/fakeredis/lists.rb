module FakeRedis
  class Redis
    module ListsMethods

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

      def llen(key)
        @data[key] ||= []
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].size
      end

      def lpop(key)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].delete_at(0)
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

      def lrange(key, startidx, endidx)
        return unless @data[key]
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key][startidx..endidx]
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

      def lset(key, index, value)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        raise RuntimeError unless index < @data[key].size
        @data[key][index] = value
      end

      def ltrim(key, start, stop)
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        @data[key] = @data[key][start..stop]
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

    end

    include ListsMethods
  end
end
