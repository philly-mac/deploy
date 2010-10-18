module Deploy
  module Base
    class << self
      attr_accessor :remote_commands

      def remote(command)
        self.remote_commands ||= []
        self.remote_commands << command
      end

      def push!
        r_commands = self.remote_commands.map do |r_command|
          puts "REMOTE: #{r_command}"
          r_command
        end.join(" && ")

        system "ssh #{config.user_name}@#{config.remote} #{r_commands}"
      end
    end
  end
end
