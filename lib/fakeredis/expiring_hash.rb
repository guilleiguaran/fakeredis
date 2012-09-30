module FakeRedis
  # Represents a normal hash with some additional expiration information
  # associated with each key
  class ExpiringHash < Hash
    attr_reader :expires

    def initialize(*)
      super
      @expires = {}
    end

    def [](key)
      delete(key) if expired?(key)
      super
    end

    def []=(key, val)
      expire(key)
      super
    end

    def delete(key)
      expire(key)
      super
    end

    def expire(key)
      expires.delete(key)
    end

    def expired?(key)
      expires.include?(key) && expires[key] < Time.now
    end

    def key?(key)
      delete(key) if expired?(key)
      super
    end

    def values_at(*keys)
      keys.each {|key| delete(key) if expired?(key)}
      super
    end

    def keys
      super.select do |key|
        if expired?(key)
          delete(key)
          false
        else
          true
        end
      end
    end
  end
end
