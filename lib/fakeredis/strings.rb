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

      def mapped_mget(*keys)
        reply = mget(*keys)
        Hash[*keys.zip(reply).flatten]
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

      def setnx(key, value)
        set(key, value) unless @data.key?(key)
      end

      def setrange(key, offset, value)
        return unless @data[key]
        s = @data[key][offset,value.size]
        @data[key][s] = value
      end

      def strlen(key)
        return unless @data[key]
        @data[key].size
      end

      alias [] get
      alias []= set
    end

    include StringsMethods
  end
end
