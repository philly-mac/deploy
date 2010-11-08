module Deploy
  module Base
    attr_accessor :remote_commands
    
    def remote_commands
      @remote_commands ||= []
    end

    def remote(command)
      self.remote_commands << command
    end

    def push!
      unless self.remote_commands.empty?
        r_commands = self.remote_commands.map do |r_command|
          puts "REMOTE: #{r_command}"
          r_command
        end.join("; ")

        puts "PUSH! ssh #{config.user_name}@#{config.remote} #{r_commands}\n\n\n"

        # system "ssh #{config.user_name}@#{config.remote} #{r_commands}"
        self.remote_commands = []
      end
    end
  end
end
