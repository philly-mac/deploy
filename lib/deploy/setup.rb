module Deploy
  class Setup

    class << self

      def init(options, summary)

        # Check whether we have the minimum set of options
        [:recipe, :environment, :method].each do |param|
          unless options.keys.include?(param)
            puts summary
            return 1
          end
        end

        # Assaign the parsed options to local variables
        recipe         = options[:recipe]
        method         = options[:method]
        config_file    = options[:config]

        config.set :env,     options[:environment]
        config.set :dry_run, options[:dry]
        config.set :verbose, config.get(:dry_run) ? true : !options[:quiet]

        # Set the configuration options
        config.set :deploy_root, "/var/www"
        config.set :app_name,    "test"
        config.set :shell,       "/bin/bash"

        config_environment
        custom_config(config_file) if config_file

        # Map short names for the recipes
        map_default_recipes

        # Load the recipe
        recipe_clazz = nil
        begin
          # Check if we are using an alias
          alias_recipe = config.get_clazz(recipe)
          recipe = alias_recipe if alias_recipe && alias_recipe != recipe

          require "deploy/recipes/#{recipe}"
          recipe_clazz = eval("::Deploy::Recipes::#{::Deploy::Util.camelize(recipe)}")
        rescue Exception => e
          puts "Error: #{e}"
          # The recipe that was specified does not exist in the default recipes
        end

        custom_recipe = "#{VIRTUAL_APP_ROOT}/deploy/recipes/#{recipe}.rb"

        if File.exists?(custom_recipe)
          require custom_recipe
          recipe_clazz = eval("::#{::Deploy::Util.camelize(recipe)}")
        end

        recipe_clazz.send(method.to_sym) if recipe_clazz

        return 0
      end

      def map_default_recipes
        config.set_clazz "pdm", "padrino_data_mapper"
        config.set_clazz "rdm", "rails_data_mapper"
        config.set_clazz "pn",  "protonet"
      end

      def config_environment
        load_config("#{VIRTUAL_APP_ROOT}/deploy/environments/#{config.get(:env)}.rb")
      end

      def custom_config(file)
        load_config(file)
      end

      def load_config(file)
        if File.exists?(file)
          file_contents = ""
          File.open(file, "r") do |infile|
            while (line = infile.gets)
              file_contents += line
            end
          end
          eval file_contents
        end
        set_paths!
      end

      def set_paths!
        config.set :app_root,      "#{config.get(:deploy_root)}/#{config.get(:app_name)}"
        config.set :current_path,  "#{config.get(:app_root)}/current"
        config.set :shared_path,   "#{config.get(:app_root)}/shared"
        config.set :releases_path, "#{config.get(:app_root)}/releases"
      end

      def set(key,value)
        config.set(key,value)
      end

    end
  end
end

