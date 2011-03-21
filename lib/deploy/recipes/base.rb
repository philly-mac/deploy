module Deploy
  module Recipes
    class Base

      include ::Deploy::Base
      include ::Deploy::RemoteCommands

      class << self

        def descriptions
          @@descriptions ||= []
        end

        def desc(method_name, description)
          descriptions << [method_name, description]
        end

        def all_descriptions
          descriptions.sort{|a,b| a.first <=> b.first}
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

