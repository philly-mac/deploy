module Deploy
  module Recipes
    class Base

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self
        attr_accessor :config

        protected

        def update_rvm
          remote "rvm update"
          remote "rvm reload"
        end

      end
    end
  end
end

