module Deploy
  module Base
    attr_accessor :commands

    def commands
      @commands ||= []
    end

    def remote(command)
      self.commands << [:remote, command]
    end

    def local(command)
      self.commands << [:local, command]
    end

    def run_now!(command)
      puts "EXECUTING: #{command}" if config.verbose
      system command unless config.dry_run
    end

    def push!
      unless self.commands.empty?
        all_commands = self.commands.map do |command|
          if command.first == :local
            puts "LOCAL: #{command.last}" if config.verbose
            eval command.last
            nil
          elsif command.first == :remote
            puts "REMOTE: #{command.last}" if config.verbose
            command.last
          end
        end

        all_commands = all_commands.compact.join("; ")

        cmd = "ssh "
        cmd << "#{config.extra_ssh_options} " if !config.extra_ssh_options.nil?
        cmd << "#{config.username}@#{config.remote} "
        cmd << "'"
        cmd << "#{config.after_login}; " if !config.after_login.nil?
        cmd << "#{all_commands}"
        cmd << "'"
        run_now! cmd
        puts "\n"
        self.commands = []
      end
    end
  end
end

