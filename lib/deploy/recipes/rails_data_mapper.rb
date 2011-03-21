module Deploy
  module Recipes
    class RailsDataMapper < ::Deploy::Recipes::Base

      extend ::Deploy::Recipes::Common

      class << self

        def setup_db
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:create RAILS_ENV=#{Config.get(:env)}"
        end


        def auto_upgrade
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:autoupgrade RAILS_ENV=#{Config.get(:env)}"
        end

        def auto_migrate
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:automigrate RAILS_ENV=#{Config.get(:env)}"
        end

      end

    end
  end
end

