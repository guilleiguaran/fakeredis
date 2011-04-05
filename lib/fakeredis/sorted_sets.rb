module FakeRedis
  class Redis
    module SortedSetsMethods
      class Elem < String
        attr_accessor :score
        def initialize(str="", score)
          super(str)
          @score = score
        end
        def <=>(other)
          @score <=> other.score
        end
      end

      class CustomSortedSet < SortedSet
        attr_accessor :indexed_set
        def add(o)
          super(o)
          @indexed_set ||= Set.new
          @indexed_set.add(o)
        end

        def delete(o)
          super(o)
          @indexed_set ||= Set.new
          @indexed_set.delete(o)
        end
      end

      def zadd(key, score, value)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then @data[key] = CustomSortedSet.new([Elem.new(value.to_s, score)])
          when CustomSortedSet then set.delete(value.to_s) ; set.add(Elem.new(value.to_s, score))
        end
      end

      def zcard(key)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then 0
          when CustomSortedSet then set.size
        end
      end

      def zcount(key, min, max)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then 0
          when CustomSortedSet then set.select{|x| x.score >= min && x.score <= max }.size
        end
      end

      def zincrby(key, incr, value)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then @data[key] = CustomSortedSet.new([Elem.new(value.to_s, incr)])
          when CustomSortedSet then 
            score = set.to_a.select{|x| x == value.to_s}.first.score
            set.delete(value.to_s)
            set.add(Elem.new(value.to_s, score+incr))
        end
      end

      def zrange(key, start, stop)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then []
          when CustomSortedSet then set.indexed_set.to_a[start..stop]
        end
      end

      def zrangescore(key, start, stop)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then []
          when CustomSortedSet then set.to_a.reverse[start..stop]
        end
      end

      def zrank(key, value)
        fail_unless_sorted_set(key)
        case set = @data[key]
          when nil then nil
          when CustomSortedSet then set.to_a.index(value)
        end
      end

      def zscore(key, value)
        case set = @data[key]
          when nil then 0
          when CustomSortedSet then set.to_a.select{|x| x == value.to_s}.first.score
        end
      end

      private

      def is_a_sorted_set?(key)
        @data[key].is_a?(CustomSortedSet) || @data[key].nil?
      end

      def fail_unless_sorted_set(key)
        fail "Not a sorted set" unless is_a_sorted_set?(key)
      end
    end
    include SortedSetsMethods
  end
end
