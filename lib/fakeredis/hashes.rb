module FakeRedis
  class Redis
    module HashesMethods
      def hdel(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key].delete(field)
      end

      def hexists(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key].key?(field)
      end

      def hget(key, field)
        return unless @data[key]
        fail "Not a hash" unless @data[key].is_a?(Hash)
        @data[key][field]
      end

      def hgetall(key)
        case hash = @data[key]
          when nil then {}
          when Hash then hash
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

      def hkeys(key)
        case hash = @data[key]
          when nil then []
          when Hash then hash.keys
          else fail "Not a hash"
        end
      end

      def hlen(key)
        case hash = @data[key]
          when nil then 0
          when Hash then hash.size
          else fail "Not a hash"
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

      def hmset(key, *fields)
        @data[key] ||= {}
        fail "Not a hash" unless @data[key].is_a?(Hash) 
        fields.each_slice(2) do |field|
          @data[key][field[0].to_s] = field[1].to_s
        end
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

      def hvals(key)
        case hash = @data[key]
          when nil then []
          when Hash then hash.values
          else fail "Not a hash"
        end
      end
    end

    include HashesMethods
  end
end
