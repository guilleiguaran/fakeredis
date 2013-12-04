class Redis
	module Commands
		# Class related to hashes commands
		#
		# Unimplemented commands:
		#
		# => HINCRBYFLOAT
		# => HSCAN
		# 
		# Implemented fake commands:
		#
		# => HDEL
		# => HINCRBY
		# => HMGET
		# => HSET
		# => HSETNX
		# => HMSET
		# => HLEN
		# => HVALS
		# => HEXISTS
		# => HGET
		# => HGETALL
		# => HKEYS
		module Hashes
			def hdel(key, field)
        field = field.to_s
        data_type_check(key, Hash)
        data[key] && data[key].delete(field)
        remove_key_for_empty_collection(key)
      end

      def hincrby(key, field, increment)
        data_type_check(key, Hash)
        field = field.to_s
        if data[key]
          data[key][field] = (data[key][field].to_i + increment.to_i).to_s
        else
          data[key] = { field => increment.to_s }
        end
        data[key][field].to_i
      end

      def hmget(key, *fields)
        raise_argument_error('hmget')  if fields.empty?

        data_type_check(key, Hash)
        fields.map do |field|
          field = field.to_s
          if data[key]
            data[key][field]
          else
            nil
          end
        end
      end

      def hset(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        if data[key]
          result = !data[key].include?(field)
          data[key][field] = value.to_s
          result
        else
          data[key] = { field => value.to_s }
          true
        end
      end

      def hsetnx(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        return false if data[key] && data[key][field]
        hset(key, field, value)
      end

      def hmset(key, *fields)
        # mapped_hmset gives us [[:k1, "v1", :k2, "v2"]] for `fields`. Fix that.
        fields = fields[0] if mapped_param?(fields)
        raise_argument_error('hmset') if fields.empty?

        is_list_of_arrays = fields.all?{|field| field.instance_of?(Array)}

        raise_argument_error('hmset') if fields.size.odd? and !is_list_of_arrays
        raise_argument_error('hmset') if is_list_of_arrays and !fields.all?{|field| field.length == 2}

        data_type_check(key, Hash)
        data[key] ||= {}

        if is_list_of_arrays
          fields.each do |pair|
            data[key][pair[0].to_s] = pair[1].to_s
          end
        else
          fields.each_slice(2) do |field|
            data[key][field[0].to_s] = field[1].to_s
          end
        end
      end

      def hlen(key)
        data_type_check(key, Hash)
        return 0 unless data[key]
        data[key].size
      end

      def hvals(key)
        data_type_check(key, Hash)
        return [] unless data[key]
        data[key].values
      end
     
      def hexists(key, field)
        data_type_check(key, Hash)
        return false unless data[key]
        data[key].key?(field.to_s)
      end

      def hgetall(key)
        data_type_check(key, Hash)
        data[key].to_a.flatten || {}
      end

      def hget(key, field)
        data_type_check(key, Hash)
        data[key] && data[key][field.to_s]
      end
     
      def hkeys(key)
        data_type_check(key, Hash)
        return [] if data[key].nil?
        data[key].keys
      end
		end
	end
end