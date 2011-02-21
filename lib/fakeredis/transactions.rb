module FakeRedis
  class Redis
    module TransactionsMethods

      def multi
        yield if block_given?
      end

    end

    include TransactionsMethods
  end
end
