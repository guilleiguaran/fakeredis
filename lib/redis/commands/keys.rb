class Redis
  module Commands
    # Class related to the Keys commands
    #
    # Unimplemented commands:
    #
    # => MIGRATE
    # => PTTL
    # => DUMP
    # => PEXPIRE
    # => RESTORE
    # => PEXPIREAT
    # => SORT
    #
    # Implemented fake commands:
    #
    # => DEL
    # => TTL
    # => RANDOMKEY
    # => EXISTS
    # => RENAME
    # => EXPIRE
    # => PERSIST
    # => RENAMENX
    # => MOVE
    # => TYPE
    module Keys

      def del(*keys)
        keys = keys.flatten(1)
        raise_argument_error('del') if keys.empty?

        old_count = data.keys.size
        keys.each do |key|
          data.delete(key)
        end
        old_count - data.keys.size
      end

      def move key, destination_id
        raise Redis::CommandError, "ERR source and destination objects are the same" if destination_id == database_id
        destination = find_database(destination_id)
        return false unless data.has_key?(key)
        return false if destination.has_key?(key)
        destination[key] = data.delete(key)
        true
      end
      
      def randomkey
        data.keys[rand(dbsize)]
      end
      
      def rename(key, new_key)
        return unless data[key]
        data[new_key] = data[key]
        data.expires[new_key] = data.expires[key] if data.expires.include?(key)
        data.delete(key)
      end
      
      def exists(key)
        data.key?(key)
      end      
      
      def ttl(key)
        if data.expires.include?(key) && (ttl = data.expires[key].to_i - Time.now.to_i) > 0
          ttl
        else
          -1
        end
      end
      
      def expire(key, ttl)
        return unless data[key]
        data.expires[key] = Time.now + ttl
        true
      end
      
      def persist(key)
        !!data.expires.delete(key)
      end

      def renamenx(key, new_key)
        if exists(new_key)
          false
        else
          rename(key, new_key)
          true
        end
      end
      
      def expireat(key, timestamp)
        data.expires[key] = Time.at(timestamp)
        true
      end
      
      def keys(pattern = "*")
        data.keys.select { |key| File.fnmatch(pattern, key) }
      end
      
      def type(key)
        case data[key]
          when nil then "none"
          when String then "string"
          when Hash then "hash"
          when Array then "list"
          when ::Set then "set"
        end
      end 
      
    end    
  end
end