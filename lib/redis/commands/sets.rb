class Redis
	module Commands
		# Class related to sets commands
		#
		# Unimplemented commands:
		#
		# => SSCAN
		# 
		# Implemented fake commands:
		#
		# => SMEMBERS
		# => SISMEMBER
		# => SADD
		# => SREM
		# => SMOVE
		# => SPOP
		# => SCARD
		# => SINTER
		# => SINTERSTORE
		# => SUNION
		# => SUNIONSTORE
		# => SDIFF
		# => SDIFFSTORE
		# => SRANDMEMBER
		module Sets

      def smembers(key)
        data_type_check(key, ::Set)
        return [] unless data[key]
        data[key].to_a.reverse
      end

      def sismember(key, value)
        data_type_check(key, ::Set)
        return false unless data[key]
        data[key].include?(value.to_s)
      end

      def sadd(key, value)
        data_type_check(key, ::Set)
        value = Array(value)
        raise_argument_error('sadd') if value.empty?

        result = if data[key]
          old_set = data[key].dup
          data[key].merge(value.map(&:to_s))
          (data[key] - old_set).size
        else
          data[key] = ::Set.new(value.map(&:to_s))
          data[key].size
        end

        # 0 = false, 1 = true, 2+ untouched
        return result == 1 if result < 2
        result
      end

      def srem(key, value)
        data_type_check(key, ::Set)
        deleted = !!(data[key] && data[key].delete?(value.to_s))
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
        return 0 unless data[key]
        data[key].size
      end

      def sinter(*keys)
        raise_argument_error('sinter') if keys.empty?

        keys.each { |k| data_type_check(k, ::Set) }
        return ::Set.new if keys.any? { |k| data[k].nil? }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject do |set, key|
          set & key
        end.to_a
      end

      def sinterstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sinter(*keys)
        data[destination] = ::Set.new(result)
      end

      def sunion(*keys)
        keys.each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject(::Set.new) do |set, key|
          set | key
        end.to_a
      end

      def sunionstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sunion(*keys)
        data[destination] = ::Set.new(result)
      end

      def sdiff(key1, *keys)
        [key1, *keys].each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject(data[key1] || Set.new) do |memo, set|
          memo - set
        end.to_a
      end

      def sdiffstore(destination, key1, *keys)
        data_type_check(destination, ::Set)
        result = sdiff(key1, *keys)
        data[destination] = ::Set.new(result)
      end

      def srandmember(key)
        data_type_check(key, ::Set)
        return nil unless data[key]
        data[key].to_a[rand(data[key].size)]
      end

		end
	end
end