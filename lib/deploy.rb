# Application root
APP_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/.."

# This is set to the directory where deploy is run from
VIRTUAL_APP_ROOT = "#{File.expand_path(File.new(".").path)}"

$: << "#{APP_ROOT}/lib"

def config
  Deploy::Config
end

require 'rubygems'
#require 'bundler/setup'

require 'optparse'

require 'deploy/config'
require 'deploy/extensions'
require 'deploy/setup'
require 'deploy/base'
require 'deploy/remote_commands'

require 'deploy/recipes/base'
require 'deploy/recipes/common'
