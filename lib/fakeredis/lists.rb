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
        fail "Not a list" unless @data[key].is_a?(Array)
        return unless @data[key]
        @data[key][startidx..endidx]
      end

      def lrem(key, value, count)
        
      end

      def rpush(key, value)
        @data[key] ||= []
        fail "Not a list" unless @data[key].is_a?(Array)
        @data[key].push(value)
      end

    end

    include ListsMethods
  end
end
