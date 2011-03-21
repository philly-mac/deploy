module Deploy
  module Recipes
    class PadrinoDataMapper < ::Deploy::Recipes::Base

      include ::Deploy::Recipes::Common

      description "setup_db", "Creates the database"
      def setup_db
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:create -e #{Config.get(:env)}"
      end

      description "auto_upgrade", "Trys to migrate the database to the current state. Won't destroy any data"
      def auto_upgrade
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:auto:upgrade -e #{Config.get(:env)}"
      end

      description "auto_migrate", "Migrates the database to the current state. This will completely destroy the data that is there"
      def auto_migrate
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:auto:migrate -e #{Config.get(:env)}"
      end

    end
  end
end

