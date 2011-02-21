module FakeRedis
  class Redis
    module ConnectionMethods

      def auth(password)
        true
      end

      def echo(string)
        string
      end

      def ping
        "PONG"
      end

      def quit ; end

      def select(index) ; end

    end

    include ConnectionMethods
  end
end
