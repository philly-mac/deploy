APP_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/.."
$: << "#{APP_ROOT}/lib"

require "deploy"

#require File.dirname(__FILE__) + "/blueprints"

class Bacon::Context
  def not_real_recipes
    ["common.rb", "base.rb"]
  end
end

# Bacon.extend(Bacon.const_get("KnockOutput"))
Bacon.extend(Bacon.const_get("TestUnitOutput"))
Bacon.summary_on_exit

