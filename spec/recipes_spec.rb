require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "All Recipes" do
  it "should run" do
    ::Deploy::Config.set :env,     'test'
    ::Deploy::Config.set :dry_run, true
    ::Deploy::Config.set :verbose, false
    ::Deploy::Config.set :deploy_root, "/var/www"
    ::Deploy::Config.set :app_name,    "test"
    ::Deploy::Config.set :shell,       "/bin/bash"

    recipes.each do |recipe, recipe_methods|
      options = {
        :environment => 'test',
        :dry         => true,
        :quiet       => true,
      }

      recipe_methods.each do |recipe_method|
        options[:recipe] = recipe.to_s
        options[:method] = recipe_method
        ::Deploy::Setup.init(options, "").should == 0
      end
    end
  end
end

