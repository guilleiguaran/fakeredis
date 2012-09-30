module FakeRedis
  class ZSet < Hash

    def []=(key, val)
      super(key, _floatify(val))
    end

    # Increments the value of key by val
    def increment(key, val)
      self[key] += _floatify(val)
    end

    def select_by_score min, max
      min = _floatify(min)
      max = _floatify(max)
      reject {|_,v| v < min || v > max }
    end

    # Originally lifted from redis-rb
    def _floatify(str)
      if (( inf = str.to_s.match(/^([+-])?inf/i) ))
        (inf[1] == "-" ? -1.0 : 1.0) / 0.0
      else
        Float str
      end
    end

  end
end
