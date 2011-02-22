module FakeRedis
  class Redis
    module KeysMethods

      def del(*keys)
        old_count = @data.keys.size
        keys.flatten.each do |key|
          @data.delete(key)
          @expires.delete(key)
        end
        deleted_count = old_count - @data.keys.size
      end

      def exists(key)
        @data.key?(key)
      end

      def expire(key, ttl)
        return @expires[key]
        @expires[key] = Time.now + ttl
        true
      end

      def expireat(key, timestamp)
        return @expires[key]
        @expires[key] = Time.at(timestamp)
        true
      end

      def keys(pattern)
        regexp = Regexp.new(pattern.split("*").map { |r| Regexp.escape(r) }.join(".*"))
        @data.keys.select { |key| key =~ regexp }
      end

      def persist(key)
        @expires[key] = -1
      end

      def randomkey
        @data.keys[rand(dbsize)]
      end

      def rename(key, new_key)
        return unless @data[key]
        @data[new_key] = @data[key]
        @expires[new_key] = @expires[key]
        @data.delete(key)
        @expires.delete(key)
      end

      def renamenx(key, new_key)
        rename(key, new_key) unless exists(new_key)
      end

      def sort(key)
        # TODO: Impleent
      end

      def ttl(key)
        @expires[key]
      end

      def type(key)
        case value = @data[key]
          when nil then "none"
          when String then "string"
          when Hash then "hash"
          when Array then "list"
          when Set then "set"
        end
      end

      protected
      def expired?(key)
        return false if @expires[key] == -1
        return true if @expires[key] && @expires[key] < Time.now
      end

    end

    include KeysMethods
  end
end
