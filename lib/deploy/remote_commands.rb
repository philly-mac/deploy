module Deploy
  module RemoteCommands
    def mkdir(dir_name, permissions = nil, remote = true)
      commands = [ "mkdir -p #{dir_name}" ]
      commands << "chmod #{permissions} #{dir_name}" if permissions
      commands = commands.join(" && ")
      remote commands
    end

    def file_not_exists(file, commands)
      commands = commands.join(" && ")
      remote "if [[ ! -e #{file} ]]; then #{commands}; fi"
    end

    def file_exists(file, commands)
      commands = commands.join(" && ")
      remote "if [[ -e #{file} ]]; then #{commands}; fi"
    end

    def link_exists(file, commands)
      commands = commands.join(" && ")
      remote "if [[ -L #{file} ]]; then #{commands}; fi"
    end

    def link_not_exists(file, commands)
      commands = commands.join(" && ")
      remote "if [[ ! -L #{file} ]]; then #{commands}; fi"
    end

    def on_good_exit(test, commands)
      remote test
      commands = commands.join(" && ")
      remote "if [[ $? = 0 ]]; then #{commands}; fi"
    end

    def on_bad_exit(test, commands)
      remote test
      commands = commands.join(" && ")
      remote "if [[ $? -ne 0 ]]; then #{commands}; fi"
    end
  end
end

