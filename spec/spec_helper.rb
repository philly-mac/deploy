require 'sham'
require 'ffaker'

require 'rack/test'
# require 'rack/flash/test'

require File.dirname(__FILE__) + "/blueprints"


# Bacon.extend(Bacon.const_get("KnockOutput"))
Bacon.extend(Bacon.const_get("TestUnitOutput"))
Bacon.summary_on_exit

