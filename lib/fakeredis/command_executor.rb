module FakeRedis
  module CommandExecutor
    def write(command)
      meffod = command[0].to_s.downcase.to_sym
      args = command[1..-1]

      if in_multi && !(TRANSACTION_COMMANDS.include? meffod) # queue commands
        queued_commands << [meffod, *args]
        reply = 'QUEUED'
      elsif respond_to?(meffod) && method(meffod).arity.zero?
        reply = send(meffod)
      elsif respond_to?(meffod)
        reply = send(meffod, *args)
      else
        raise Redis::CommandError, "ERR unknown command '#{meffod}'"
      end

      if reply == true
        reply = 1
      elsif reply == false
        reply = 0
      elsif reply.is_a?(Array)
        reply = reply.map { |r| r == true ? 1 : r == false ? 0 : r }
      end

      replies << reply
      nil
    end
  end
end
