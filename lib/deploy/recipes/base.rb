module Deploy
  module Recipes
    class Base

      include ::Deploy::Base
      include ::Deploy::RemoteCommands

      class << self

        def desc
          @@descriptions ||= []
        end

        def description(method_name, description)
          desc << [method_name, description]
        end

        def descriptions
          desc.sort{|a,b| a.first <=> b.first}
        end

        def actions=(actions)
          @@actions = actions
        end

        def actions
          @@actions ||= []
          @@actions
        end

        def run_actions(run_clazz)
          actions.each do |action|
            puts "\n*** #{action} ***" if Config.get(:verbose)
            run_clazz.send action
            run_clazz.push!
          end
        end

      end
    end
  end
end

