require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "All Recipes" do
  it "should run" do
    #TODO finish this
    Dir["#{APP_ROOT}/lib/deploy/recipes/*.rb"].each do |recipe|
      unless not_real_recipes.include?(recipe)
        puts recipe.methods(false)
      end

    end
  end
end

