module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self

        def my_methods

        end

        def actions=(actions)
          @@actions = actions
        end

        def actions
          @@actions ||= []
          @@actions
        end

        def run_actions(after_spec = nil)
          actions.each do |action|
            puts "\n*** #{action} ***" if Config.get(:verbose)
            self.send action
            push!
            if after_spec && after_spec[:after] == action
              after_spec[:actions] = [after_spec[:actions]] if !after_spec[:actions].is_a?(Array)
              after_spec[:actions].each{|as_action| self.send(as_action); push! }
            end
          end
        end

      end
    end
  end
end

