class Redis
  module Commands
    # Class related to the strings commands
    #
    # Unimplemented commands:
    #
    # => BITOP
    # => INCRBYFLOAT
    #
    # Implemented fake commands:
    #
    # => APPEND
    # => GETBIT
    # => MGET
    # => SETEX
    # => GETRANGE
    # => MSET
    # => SETNX
    # => GETSET
    # => MSETNX
    # => SETRANGE
    # => INCR
    # => DECR
    # => INCRBY
    # => DECRBY
    # => STRLEN
    # => SET
    # => GET
    # => SETBIT
    # => BITCOUNT
    module Strings
      
      def append(key, value)
        data[key] = (data[key] || "")
        data[key] = data[key] + value.to_s
      end
      
      def getbit(key, offset)
        return unless data[key]
        data[key].unpack('B*')[0].split("")[offset].to_i
      end

      def mget(*keys)
        raise_argument_error('mget') if keys.empty?
        # We work with either an array, or list of arguments
        keys = keys.first if keys.size == 1
        data.values_at(*keys)
      end
      
      def setex(key, seconds, value)
        data[key] = value.to_s
        expire(key, seconds)
        "OK"
      end
      
      def getrange(key, start, ending)
        return unless data[key]
        data[key][start..ending]
      end
      alias :substr :getrange
      
      def mset(*pairs)
        # Handle pairs for mapped_mset command
        pairs = pairs[0] if mapped_param?(pairs)
        raise_argument_error('mset') if pairs.empty? || pairs.size.odd?

        pairs.each_slice(2) do |pair|
          data[pair[0].to_s] = pair[1].to_s
        end
        "OK"
      end
      
      def setnx(key, value)
        if exists(key)
          false
        else
          set(key, value)
          true
        end
      end

      def getset(key, value)
        data_type_check(key, String)
        data[key].tap do
          set(key, value)
        end
      end
      
      def msetnx(*pairs)
        # Handle pairs for mapped_msetnx command
        pairs = pairs[0] if mapped_param?(pairs)
        keys = []
        pairs.each_with_index{|item, index| keys << item.to_s if index % 2 == 0}
        return false if keys.any?{|key| data.key?(key) }
        mset(*pairs)
        true
      end   

      def setrange(key, offset, value)
        return unless data[key]
        s = data[key][offset,value.size]
        data[key][s] = value
      end

      def incr(key)
        data.merge!({ key => (data[key].to_i + 1).to_s || "1"})
        data[key].to_i
      end

      def incrby(key, by)
        data.merge!({ key => (data[key].to_i + by.to_i).to_s || by })
        data[key].to_i
      end

      def decr(key)
        data.merge!({ key => (data[key].to_i - 1).to_s || "-1"})
        data[key].to_i
      end

      def decrby(key, by)
        data.merge!({ key => ((data[key].to_i - by.to_i) || (by.to_i * -1)).to_s })
        data[key].to_i
      end

      def strlen(key)
        return unless data[key]
        data[key].size
      end

      def set(key, value)
        data[key] = value.to_s
        "OK"
      end

      def get(key)
        data_type_check(key, String)
        data[key]
      end

      def setbit(key, offset, bit)
        old_val = data[key] ? data[key].unpack('B*')[0].split("") : []
        size_increment = [((offset/8)+1)*8-old_val.length, 0].max
        old_val += Array.new(size_increment).map{"0"}
        original_val = old_val[offset]
        old_val[offset] = bit.to_s
        new_val = ""
        old_val.each_slice(8){|b| new_val = new_val + b.join("").to_i(2).chr }
        data[key] = new_val
        original_val
      end

      def bitcount(key, start = 0, ending = nil)
        return 0 unless data[key]

        ending = data[key].length unless ending

        data[key].unpack('B*')[0][start..ending].count('1')
      end

    end
  end
end
