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

      self.desc "revert", "Reverts a one of the previous deployments"
      def revert
        remote "cd #{config.get(:releases_path)}"
        remote <<EOC
          counter=1
          FILES=#{config.get(:releases_path)}/*
          echo "Revert to which deployment?"
          for f in $FILES; do releases[$counter]=$f; echo "${counter}. $f"; counter=$(( counter + 1 )); done
          read answer
          echo "About to revert to ${releases[$answer]}"
          rm #{config.get(:current_path)}
          ln -s ${releases[$answer]} #{config.get(:current_path)}
          touch #{config.get(:current_path)}/tmp/restart.txt
EOC
        push!
      end
    end
  end
end

