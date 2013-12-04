require 'fakeredis/sorted_set_argument_handler'
require 'fakeredis/sorted_set_store'
require 'fakeredis/zset'

class Redis
	module Commands
		# Class related to sorted sets commands
		#
		# Unimplemented commands:
		#
		# => ZSCAN
		# 
		# Implemented fake commands:
		#
		# => ZADD
		# => ZREM
		# => ZCARD
		# => ZSCORE
		# => ZCOUNT
		# => ZINCRBY
		# => ZRANK
		# => ZREVRANK
		# => ZRANGE
		# => ZRANGEBYSCORE
		# => ZREVRANGE
		# => ZREVRANGEBYSCORE
		# => ZINTERSTORE
		# => ZUNIONSTORE
		# => ZREMRANGEBYRANK
		module SortedSets

      def zadd(key, *args)
        if !args.first.is_a?(Array)
          if args.size < 2
            raise_argument_error('zadd')
          elsif args.size.odd?
            raise_syntax_error
          end
        else
          unless args.all? {|pair| pair.size == 2 }
            raise_syntax_error
          end
        end

        data_type_check(key, FakeRedis::ZSet)
        data[key] ||= FakeRedis::ZSet.new

        if args.size == 2 && !(Array === args.first)
          score, value = args
          exists = !data[key].key?(value.to_s)
          data[key][value.to_s] = score
        else
          # Turn [1, 2, 3, 4] into [[1, 2], [3, 4]] unless it is already
          args = args.each_slice(2).to_a unless args.first.is_a?(Array)
          exists = args.map(&:last).map { |el| data[key].key?(el.to_s) }.count(false)
          args.each { |s, v| data[key][v.to_s] = s }
        end

        exists
      end

      def zrem(key, value)
        data_type_check(key, FakeRedis::ZSet)
        values = Array(value)
        return 0 unless data[key]

        response = values.map do |v|
          data[key].delete(v.to_s) if data[key].has_key?(v.to_s)
        end.compact.size

        remove_key_for_empty_collection(key)
        response
      end

      def zcard(key)
        data_type_check(key, FakeRedis::ZSet)
        data[key] ? data[key].size : 0
      end

      def zscore(key, value)
        data_type_check(key, FakeRedis::ZSet)
        value = data[key] && data[key][value.to_s]
        value && value.to_s
      end

      def zcount(key, min, max)
        data_type_check(key, FakeRedis::ZSet)
        return 0 unless data[key]
        data[key].select_by_score(min, max).size
      end

      def zincrby(key, num, value)
        data_type_check(key, FakeRedis::ZSet)
        data[key] ||= FakeRedis::ZSet.new
        data[key][value.to_s] ||= 0
        data[key].increment(value.to_s, num)
        data[key][value.to_s].to_s
      end

      def zrank(key, value)
        data_type_check(key, FakeRedis::ZSet)
        z = data[key]
        return unless z
        z.keys.sort_by {|k| z[k] }.index(value.to_s)
      end

      def zrevrank(key, value)
        data_type_check(key, FakeRedis::ZSet)
        z = data[key]
        return unless z
        z.keys.sort_by {|k| -z[k] }.index(value.to_s)
      end

      def zrange(key, start, stop, with_scores = nil)
        data_type_check(key, FakeRedis::ZSet)
        return [] unless data[key]

        # Sort by score, or if scores are equal, key alphanum
        results = data[key].sort do |(k1, v1), (k2, v2)|
          if v1 == v2
            k1 <=> k2
          else
            v1 <=> v2
          end
        end
        # Select just the keys unless we want scores
        results = results.map(&:first) unless with_scores
        results[start..stop].flatten.map(&:to_s)
      end

      def zrevrange(key, start, stop, with_scores = nil)
        data_type_check(key, FakeRedis::ZSet)
        return [] unless data[key]

        if with_scores
          data[key].sort_by {|_,v| -v }
        else
          data[key].keys.sort_by {|k| -data[key][k] }
        end[start..stop].flatten.map(&:to_s)
      end

      def zrangebyscore(key, min, max, *opts)
        data_type_check(key, FakeRedis::ZSet)
        return [] unless data[key]

        range = data[key].select_by_score(min, max)
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
        data_type_check(key, FakeRedis::ZSet)
        return [] unless data[key]

        range = data[key].select_by_score(min, max)
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
        data_type_check(key, FakeRedis::ZSet)
        return 0 unless data[key]

        range = data[key].select_by_score(min, max)
        range.each {|k,_| data[key].delete(k) }
        range.size
      end

      def zinterstore(out, *args)
        data_type_check(out, FakeRedis::ZSet)
        args_handler = FakeRedis::SortedSetArgumentHandler.new(args)
        data[out] = FakeRedis::SortedSetIntersectStore.new(args_handler, data).call
        data[out].size
      end

      def zunionstore(out, *args)
        data_type_check(out, FakeRedis::ZSet)
        args_handler = FakeRedis::SortedSetArgumentHandler.new(args)
        data[out] = FakeRedis::SortedSetUnionStore.new(args_handler, data).call
        data[out].size
      end

      def zremrangebyrank(key, start, stop)
        sorted_elements = data[key].sort_by { |k, v| v }
        start = sorted_elements.length if start > sorted_elements.length
        elements_to_delete = sorted_elements[start..stop]
        elements_to_delete.each { |elem, rank| data[key].delete(elem) }
        elements_to_delete.size
      end

		end
	end
end