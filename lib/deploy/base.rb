module Deploy
  class Base
    class << self
      attr_accessor :local_commands
      attr_accessor :remote_commands

      def remote(command)
        self.remote_commands ||= []
        self.remote_commands << command
      end

      def local(command)
        self.local_commands ||= []
        self.local_commands << command
      end

      def push(type)
        if type == :local
          self.local_commands.map do |l_command|
            puts "LOCAL: #{l_command}"
            system l_command
          end
        elsif type == :remote
          config = ::Deploy::Config
          config.setup

          r_commands = self.remote_commands.map do |r_command|
            puts "REMOTE: #{r_command}"
            r_command
          end.join(" && ")

          system "ssh #{config.user}@#{config.remote} #{r_commands}"
        end
      end
    end
  end
end
