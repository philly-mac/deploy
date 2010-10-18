module Deploy
  module RemoteCommands
    def mkdir(dir_name, permissions = nil)
      remote "mkdir -p #{dir_name}"
      remote "chmod #{permissions} #{dir_name}" if permissions
    end

    def on_good_exit(test, command)
      remote test
      remote "if [ $? = 0 ]; then bash -c #{command}; fi"

      if command.is_a?(String)
        remote "if [ $? = 0 ]; then bash -c #{command}; fi"
      elsif command.is_a?(Symbol)
        "if [ $? = 0 ]; then bash -c #{send command, *args}; fi"
      end
    end

    def on_bad_exit(test, command, *args)
      remote test
      if command.is_a?(String)
        remote "if [ $? -ne 0 ]; then bash -c #{command}; fi"
      elsif command.is_a?(Symbol)
        "if [ $? -ne 0 ]; then bash -c #{send command, *args}; fi"
      end
    end
  end
end
