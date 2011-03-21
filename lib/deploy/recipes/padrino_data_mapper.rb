module Deploy
  module Recipes
    class PadrinoDataMapper < ::Deploy::Recipes::Base

      extend ::Deploy::Recipes::Common

      class << self

        def setup_db
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec padrino rake dm:create -e #{Config.get(:env)}"
        end


        def auto_upgrade
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec padrino rake dm:auto:upgrade -e #{Config.get(:env)}"
        end

        def auto_migrate
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec padrino rake dm:auto:migrate -e #{Config.get(:env)}"
        end

      end

    end
  end
end

