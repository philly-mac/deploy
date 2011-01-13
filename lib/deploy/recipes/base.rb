module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self

        attr_accessor :base_deploy_actions

        def task(method_name, &block)
          eigenklazz.instance_eval do
            define_method(method_name) do
              yield block
            end
          end
        end

        def job(method_name, &block)
          eigenklazz.instance_eval do
            define_method(method_name) do  |*args|
              puts "\n*** #{method_name} ***" if config.verbose
              delay_push = args.first
              delay_push ||= false
              yield block
              push! unless delay_push
            end
          end
        end

        def eigenklazz
          (class << self; self; end)
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

