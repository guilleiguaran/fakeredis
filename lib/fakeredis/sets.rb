module FakeRedis
  class Redis
    module SetsMethods
      def sadd(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then @data[key] = Set.new([value.to_s])
          when Set then set.add(value.to_s)
        end
      end

      def scard(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then 0
          when Set then set.size
        end
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

      def sismember(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then false
          when Set then set.include?(value.to_s)
        end
      end

      def smembers(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then []
          when Set then set.to_a
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

      def srandmember(key)
        fail_unless_set(key)
        case set = @data[key]
          when nil then nil
          when Set then set.to_a[rand(set.size)]
        end
      end

      def srem(key, value)
        fail_unless_set(key)
        case set = @data[key]
          when nil then return
          when Set then set.delete(value.to_s)
        end
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

      private

      def is_a_set?(key)
        @data[key].is_a?(Set) || @data[key].nil?
      end

      def fail_unless_set(key)
        fail "Not a set" unless is_a_set?(key)
      end
    end

    include SetsMethods
  end
end
