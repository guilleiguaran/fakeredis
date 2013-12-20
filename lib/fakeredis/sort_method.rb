# Codes are mostly referenced from MockRedis' implementation.
module FakeRedis
  module SortMethod
    def sort(key, options = {})
      return [] unless key

      unless %w(list set zset).include? type(key)
        warn "Operation against a key holding the wrong kind of value: Expected list, set or zset at #{key}."
        raise Redis::CommandError.new("WRONGTYPE Operation against a key holding the wrong kind of value")
      end

      by           = options[:by]
      limit        = options[:limit] || []
      store        = options[:store]
      get_patterns = Array(options[:get])
      order        = options[:order] || "ASC"
      direction    = order.split.first

      projected = project(data[key], by, get_patterns)
      sorted    = sort_by(projected, direction)
      sliced    = slice(sorted, limit)

      store ? rpush(store, sliced) : sliced
    end

    private

    ASCENDING_SORT  = Proc.new { |a, b| a.first <=> b.first }
    DESCENDING_SORT = Proc.new { |a, b| b.first <=> a.first }

    def project(enumerable, by, get_patterns)
      enumerable.map do |*elements|
        element = elements.flatten.first
        weight  = by ? lookup_from_pattern(by, element) : element
        value   = element

        if get_patterns.length > 0
          value = get_patterns.map do |pattern|
            pattern == "#" ? element : lookup_from_pattern(pattern, element)
          end
          value = value.first if value.length == 1
        end

        [weight, value]
      end
    end

    def sort_by(projected, direction)
      sorter =
        case direction.upcase
          when "DESC"
            DESCENDING_SORT
          when "ASC", "ALPHA"
            ASCENDING_SORT
          else
            raise "Invalid direction '#{direction}'"
        end

      projected.sort(&sorter).map(&:last)
    end

    def slice(sorted, limit)
      skip = limit.first || 0
      take = limit.last || sorted.length

      sorted[skip...(skip + take)] || sorted
    end

    def lookup_from_pattern(pattern, element)
      key = pattern.sub('*', element)

      if (hash_parts = key.split('->')).length > 1
        hget hash_parts.first, hash_parts.last
      else
        get key
      end
    end
  end
end
