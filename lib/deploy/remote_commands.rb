module Deploy
  module RemoteCommands
    def mkdir(dir_name, permissions = nil, remote = true)
      commands = [ "mkdir -p #{dir_name}" ]
      commands << "chmod #{permissions} #{dir_name}" if permissions
      remote_or_return(commands, remote)
    end

    def file_not_exists(file, remote = true)
      commands = ["[ ! -e #{file} ]"]
      remote_or_return(commands, remote)
    end

    def file_exists(file, remote = true)
      commands = ["[ -e #{file} ]"]
      remote_or_return(commands, remote)
    end

    def on_good_exit(test, commands)
      remote test
      remote "if [ $? = 0 ]; then #{compile_commands(commands)}; fi"
    end

    def on_bad_exit(test, commands)
      remote test
      remote "if [ $? -ne 0 ]; then #{compile_commands(commands)}; fi"
    end

    def compile_commands(commands)
      all_commands = commands.map do |command|
        ret_command = ""
        if command.is_a?(Array)
          ret_command = send(command.first, *command.last)
        elsif command.is_a?(String)
          ret_command = command
        end
        ret_command
      end

      all_commands.join(" && ")
    end

    def remote_or_return(commands, remote_command)
      if remote_command
        commands.each{|c| remote c }
        return
      else
        commands.join(" && ")
      end
    end
  end
end
