module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self
        attr_accessor :config

        protected

        def task(method_name, &block)
          class_eval do
            define_method method_name do |delay_push|
              yield block
              push! unless delay_push
            end
          end
        end

        def update_rvm
          remote "rvm update"
          remote "rvm reload"
        end

      end
    end
  end
end

