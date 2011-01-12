module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self

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

      end
    end
  end
end

