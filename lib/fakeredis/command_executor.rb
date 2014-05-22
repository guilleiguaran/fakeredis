module FakeRedis
  module CommandExecutor
    def write(command)
      meffod = command.shift.to_s.downcase.to_sym

      if in_multi && !(TRANSACTION_COMMANDS.include? meffod) # queue commands
        queued_commands << [meffod, *command]
        reply = 'QUEUED'
      elsif respond_to?(meffod)
        reply = send(meffod, *command)
      else
        raise Redis::CommandError, "ERR unknown command '#{meffod}'"
      end

      if reply == true
        reply = 1
      elsif reply == false
        reply = 0
      end

      replies << reply
      nil
    end
  end
end
