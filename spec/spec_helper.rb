APP_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/.."
$: << "#{APP_ROOT}/lib"

require "deploy/deploy"
require "deploy/config"
require "deploy/base"
require "deploy/remote_commands"
require "deploy/utils"
#require 'sham'
#require 'ffaker'

#require File.dirname(__FILE__) + "/blueprints"


# Bacon.extend(Bacon.const_get("KnockOutput"))
Bacon.extend(Bacon.const_get("TestUnitOutput"))
Bacon.summary_on_exit

