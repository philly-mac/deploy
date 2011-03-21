module Deploy
  module Recipes
    class RailsDataMapper < ::Deploy::Recipes::Base

      include ::Deploy::Recipes::Common

      description "setup_db", "Creates the database"
      def setup_db
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec rake db:create RAILS_ENV=#{Config.get(:env)}"
      end

      description "auto_upgrade", "Trys to migrate the database to the current state. Won't destroy any data"
      def auto_upgrade
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec rake db:autoupgrade RAILS_ENV=#{Config.get(:env)}"
      end

      description "auto_migrate", "Migrates the database to the current state. This will completely destroy the data that is there"
      def auto_migrate
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec rake db:automigrate RAILS_ENV=#{Config.get(:env)}"
      end

    end
  end
end

