module FakeRedis
  module TransactionCommands
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
