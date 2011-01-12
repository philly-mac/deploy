module Deploy
  class Setup

    class << self
      attr_accessor :dry_run
      attr_accessor :verbose

      def init(options, summary)
        # Check whether we have the minimum set of options
        [:recipe, :environment, :method].each do |param|
          unless options.keys.include?(param)
            puts summary
            return 1
          end
        end

        # Assaign the parsed options to local variables
        recipe       = options[:recipe]
        env          = options[:environment]
        method       = options[:method]
        config_file  = options[:config]
        self.dry_run = options[:dry]
        self.verbose = !options[:quiet]

        self.verbose = true if self.dry_run

        # Set the configuration options
        c = ::Deploy::Config.new
        c.set :env, env
        c.config_environment
        c.config_custom(config_file) if config_file

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
          recipe_clazz.config = c
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
    end
  end
end

