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
      puts "EXECUTING: #{command}" if config.get(:verbose)
      system command unless config.get(:dry_run)
    end

    def push!
      unless self.commands.empty?
        all_commands = self.commands.map do |command|
          if command.first == :local
            puts "LOCAL: #{command.last}" if config.get(:verbose)
            eval command.last
            nil
          elsif command.first == :remote
            puts "REMOTE: #{command.last}" if config.get(:verbose)
            command.last
          end
        end

        all_commands = all_commands.compact.join("; ")

        cmd = "ssh "
        cmd << "#{config.get(:extra_ssh_options)} " unless config.get(:extra_ssh_options)
        cmd << "#{config.get(:username)}@#{config.get(:remote)} "
        cmd << "'"
        cmd << "#{config.get(:after_login)}; " unless config.get(:after_login)
        cmd << "#{all_commands}"
        cmd << "'"
        run_now! cmd
        puts "\n"
        self.commands = []
      end
    end
  end
end

