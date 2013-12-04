class Redis
	module Commands
		# Class related to lists commands
		#
		# Unimplemented commands:
		#
		# => BLPOP
		# => BRPOP
		# => BRPOPLPUSH
		# 
		# Implemented fake commands:
		#
		# => LLEN
		# => LRANGE
		# => LTRIM
		# => LINDEX
		# => LINSERT
		# => LSET
		# => LREM
		# => RPUSH
		# => RPUSHX
		# => LPUSH
		# => LPUSHX
		# => RPOP
		# => RPOPLPUSH
		# => LPOP
		module Lists
      def llen(key)
        data_type_check(key, Array)
        return 0 unless data[key]
        data[key].size
      end

      def lrange(key, startidx, endidx)
        data_type_check(key, Array)
        (data[key] && data[key][startidx..endidx]) || []
      end

      def ltrim(key, start, stop)
        data_type_check(key, Array)
        return unless data[key]

        if start < 0 && data[key].count < start.abs
          # Example: we have a list of 3 elements and
          # we give it a ltrim list, -5, -1. This means
          # it should trim to a max of 5. Since 3 < 5
          # we should not touch the list. This is consistent
          # with behavior of real Redis's ltrim with a negative
          # start argument.
          data[key]
        else
          data[key] = data[key][start..stop]
        end
      end

      def lindex(key, index)
        data_type_check(key, Array)
        data[key] && data[key][index]
      end

      def linsert(key, where, pivot, value)
        data_type_check(key, Array)
        return unless data[key]
        index = data[key].index(pivot)
        case where
          when :before then data[key].insert(index, value)
          when :after  then data[key].insert(index + 1, value)
          else raise_syntax_error
        end
      end

      def lset(key, index, value)
        data_type_check(key, Array)
        return unless data[key]
        raise Redis::CommandError, "ERR index out of range" if index >= data[key].size
        data[key][index] = value
      end

      def lrem(key, count, value)
        data_type_check(key, Array)
        return unless data[key]
        old_size = data[key].size
        diff =
          if count == 0
            data[key].delete(value)
            old_size - data[key].size
          else
            array = count > 0 ? data[key].dup : data[key].reverse
            count.abs.times{ array.delete_at(array.index(value) || array.length) }
            data[key] = count > 0 ? array.dup : array.reverse
            old_size - data[key].size
          end
        remove_key_for_empty_collection(key)
        diff
      end

      def rpush(key, value)
        data_type_check(key, Array)
        data[key] ||= []
        [value].flatten.each do |val|
          data[key].push(val.to_s)
        end
        data[key].size
      end

      def rpushx(key, value)
        data_type_check(key, Array)
        return unless data[key]
        rpush(key, value)
      end

      def lpush(key, value)
        data_type_check(key, Array)
        data[key] ||= []
        [value].flatten.each do |val|
          data[key].unshift(val.to_s)
        end
        data[key].size
      end

      def lpushx(key, value)
        data_type_check(key, Array)
        return unless data[key]
        lpush(key, value)
      end

      def rpop(key)
        data_type_check(key, Array)
        return unless data[key]
        data[key].pop
      end

      def rpoplpush(key1, key2)
        data_type_check(key1, Array)
        rpop(key1).tap do |elem|
          lpush(key2, elem)
        end
      end

      def lpop(key)
        data_type_check(key, Array)
        return unless data[key]
        data[key].shift
      end
		end
	end
end