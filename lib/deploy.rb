require 'rubygems'
#require 'bundler/setup'

require 'optparse'

require 'deploy/config'
require 'deploy/extensions'
require 'deploy/setup'
require 'deploy/base'
require 'deploy/remote_commands'

require 'deploy/recipes/base'
require 'deploy/recipes/protonet'
require 'deploy/recipes/padrino_data_mapper'
require 'deploy/recipes/rails_data_mapper'

