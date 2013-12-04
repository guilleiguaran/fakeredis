class Redis
	module Commands
		# Class related to connection commands
		# 
		# Implemented fake commands:
		#
		# => ECHO
		# => PING
		# => AUTH
		# => SELECT
		# => QUIT
		module Connection

			def auth(password)
        "OK"
      end

      def quit ; end

      def select(index)
        data_type_check(index, Integer)
        self.database_id = index
        "OK"
      end

			def echo(string)
        string
      end

      def ping
        "PONG"
      end
      
		end
	end
end