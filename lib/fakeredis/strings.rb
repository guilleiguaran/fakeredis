module FakeRedis
  class Redis
    module StringsMethods

      def append(key, value)
        @data[key] = (@data[key] || "")
        @data[key] = @data[key] + value.to_s
      end

      def decr(key)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i - 1).to_s
      end

      def decrby(key, by)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i - by.to_i).to_s
      end

      def get(key)
        #return if expired?(key)
        @data[key]
      end

      def getbit(key, offset)
        #return if expired?(key)
        return unless @data[key]
        @data[key].unpack('B8')[0].split("")[offset]
      end

      def getrange(key, start, ending)
        return unless @data[key]
        @data[key][start..ending]
      end

      def getset(key, value)
        return unless @data[key]
        old_value = @data[key]
        @data[key] = value
        return old_value
      end

      def incr(key)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i + 1).to_s
      end

      def incrby(key, by)
        @data[key] = (@data[key] || "0")
        @data[key] = (@data[key].to_i + by.to_i).to_s
      end

      def mget(*keys)
        @data.values_at(*keys)
      end

      def mset(*pairs)
        pairs.each_slice(2) do |pair|
          @data[pair[0].to_s] = pair[1].to_s
        end
        "OK"
      end

      def msetnx(key_value_pairs)

      end

      def set(key, value)
        @data[key] = value.to_s
      end

      def setbit(key, offset, value)

      end

      def setex(key, seconds, value)

      end

      def setnx(key, value)
        set(key, value) unless @data.key?(key)
      end

      def setrange(key, offset, value)

      end

      def strlen(key)

      end

      alias [] get
      alias []= set
    end

    include StringsMethods
  end
end
