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
        config.env     = options[:environment]
        method         = options[:method]
        config_file    = options[:config]
        config.dry_run = options[:dry]
        config.verbose = !options[:quiet]

        config.verbose = true if config.dry_run

        # Set the configuration options
        config.deploy_root   = "/var/www"
        config.app_name      = "test"
        config.shell         = "/bin/bash"

        config_environment
        custom_config(config_file) if config_file

        # Map short names for the recipes
        map_default_recipes

        # Load the recipe
        recipe_clazz = nil
        begin
          # Check if we are using an alias
          alias_recipe = Deploy::RecipeMap.recipe_clazz(recipe)
          recipe = alias_recipe if alias_recipe != recipe

          require "deploy/recipes/#{recipe}"
          recipe_clazz = eval("::Deploy::Recipes::#{recipe.camelize}")
        rescue Exception => e
          puts "Error: #{e}"
          # The recipe that was specified does not exist in the default recipes
        end

        custom_recipe = "#{VIRTUAL_APP_ROOT}/deploy/recipes/#{recipe}.rb"

        if File.exists?(custom_recipe)
          require custom_recipe
          recipe_clazz = eval("::#{recipe.camelize}")
        end
        if recipe_clazz
          recipe_clazz.send(method.to_sym)
          recipe_clazz.push!
        end

        return 0
      end

      def map_default_recipes
        Deploy::RecipeMap.map("padrino_data_mapper", "pdm")
        Deploy::RecipeMap.map("protonet", "pn")
        Deploy::RecipeMap.map("rails", "r")
      end

      def set_paths!
        config.app_root      = "#{config.deploy_root}/#{config.app_name}"
        config.current_path  = "#{config.app_root}/current"
        config.shared_path   = "#{config.app_root}/shared"
        config.releases_path = "#{config.app_root}/releases"
      end

      def config_environment
        load_config("#{VIRTUAL_APP_ROOT}/deploy/environments/#{config.env}.rb")
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

      def set(key, value)
        config.configure_from_hash({key => value})
      end

    end
  end
end

