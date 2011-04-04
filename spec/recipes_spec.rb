require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "All Recipes" do

  before do
    ::Deploy::Config.set :env,     'test'
    ::Deploy::Config.set :dry_run, true
    ::Deploy::Config.set :verbose, false
    ::Deploy::Config.set :deploy_root, "/var/www"
    ::Deploy::Config.set :app_name,    "test"
    ::Deploy::Config.set :shell,       "/bin/bash"

    @options = {
      :environment => 'test',
      :dry         => true,
      :quiet       => true,
    }
  end

  it "should run" do
    recipes.each do |recipe, recipe_methods|
      recipe_methods.each do |recipe_method|
        @options[:recipe] = recipe.to_s
        @options[:method] = recipe_method
        ::Deploy::Setup.init(@options, "").should == 0
      end
    end
  end

  it "should allow you to pass in parameters" do
    recipes.each do |recipe, recipe_methods|
      recipe_methods.each do |recipe_method|
        @options[:recipe] = recipe.to_s
        @options[:method] = recipe_method
        @options[:parameters] = "TEST1=test1,TEST2=test2"
        ::Deploy::Setup.init(@options, "")
        ::Deploy::Config.get("TEST1").should == "test1"
        ::Deploy::Config.get("TEST2").should == "test2"
      end
    end
  end
end

