module Deploy
  module Base
    attr_accessor :remote_commands

    def remote_commands
      @remote_commands ||= []
    end

    def remote(command)
      self.remote_commands << command
    end

    def local(command)
      puts "LOCAL: #{command}" if config.verbose
      system command unless config.dry_run
    end

    def push!
      unless self.remote_commands.empty?
        r_commands = self.remote_commands.map do |r_command|
          puts "REMOTE: #{r_command}" if config.verbose
          r_command
        end.join("; ")
        cmd = "ssh "
        cmd << "#{config.extra_ssh_options} " if !config.extra_ssh_options.nil?
        cmd << "#{config.username}@#{config.remote} "
        cmd << "'"
        cmd << "#{config.after_login}; " if !config.after_login.nil?
        cmd << "#{r_commands}"
        cmd << "'"
        local cmd
        puts "\n"
        self.remote_commands = []
      end
    end
  end
end

