module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self

        attr_accessor :base_deploy_actions

        def eigenklazz
          (class << self; self; end)
        end

        def task(method_name, delay_option = false)
          if block_given?
            eigenklazz.instance_eval do
              define_method(method_name) do |*args|
                puts "\n*** #{method_name} ***" if config.verbose
                delay_push = false
                if delay_option
                  delay_push = args.first if args.size > 0
                  yield
                else
                  yield(*args)
                  push!
                end
                push! unless delay_push
              end
            end
          end
        end

        def set_base_deploy_actions(actions)
          self.base_deploy_actions = actions
        end

        def base_deploy(after_spec = nil)
          base_deploy_actions.each do |action|
            self.send action
            if after_spec && after_spec[:after] == action
              after_spec[:actions] = [after_spec[:actions]] if !after_spec[:actions].is_a?(Array)
              after_spec[:actions].each{|as_action| self.send(as_action) }
            end
          end
        end

      end
    end
  end
end

