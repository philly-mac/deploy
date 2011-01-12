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
      puts "LOCAL: #{command}" if ::Deploy::Setup.verbose
      system command unless ::Deploy::Setup.dry_run
    end

    def push!
      unless self.remote_commands.empty?
        r_commands = self.remote_commands.map do |r_command|
          puts "REMOTE: #{r_command}" if ::Deploy::Setup.verbose
          r_command
        end.join("; ")
        cmd = "ssh "
        cmd << "#{config.extra_ssh_options} " if Deploy::Utils.present?(config.extra_ssh_options)
        cmd << "#{config.username}@#{config.remote} "
        cmd << "'"
        cmd << "#{config.after_login}; " if Deploy::Utils.present?(config.after_login)
        cmd << "#{r_commands}"
        cmd << "'"
        local cmd
        puts "\n"
        self.remote_commands = []
      end
    end
  end
end

