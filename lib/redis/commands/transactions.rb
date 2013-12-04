class Redis
	module Commands
		# Class related to transactions commands
		#
		# Unimplemented commands:
		#
		# => DISCARD
		# 
		# Implemented fake commands:
		#
		# => MULTI
		# => EXEC
		# => WATCH
		# => UNWATCH
		module Transactions
      def exec
        buffer.tap {|x| self.buffer = nil }
      end

      def multi
        self.buffer = []
        yield if block_given?
        "OK"
      end

      def watch(_)
        "OK"
      end

      def unwatch
        "OK"
      end
		end
	end
end