module Deploy
  class Deploy
    class << self
      def init(options, summary)
        # Check whether we have the minimum set of options
        [:recipe, :environment, :method].each do |param|
          unless options.keys.include?(param)
            puts summary
            exit(1)
          end
        end

        # Assaign the parsed options to local variables
        recipe      = options[:recipe]
        env         = options[:environment]
        method      = options[:method]
        config_file = options[:config]

        # Set the configuration options
        c = ::Deploy::Config.new
        c.set :env, env
        c.config_environment
        c.config_custom(config_file) if config_file

        # Load the recipe
        r = nil
        begin
          require "deploy/recipes/#{recipe}"
          r = eval("::Deploy::Recipes::#{Utils.capitalize(recipe)}")
        rescue
          # The recipe that was specified does not exist in the default recipes
        end

        custom_recipe = "#{VIRTUAL_APP_ROOT}/deploy/recipes/#{recipe}.rb"

        if File.exists?(custom_recipe)
          require custom_recipe
          r = eval("::#{Utils.capitalize(recipe)}")
        end

        if r
          r.send(method.to_sym, c)
          r.push!
        end
      end
    end
  end
end

