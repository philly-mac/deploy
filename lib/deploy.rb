require 'optparse'
require 'active_support/all'

require 'deploy/config'
require 'deploy/recipe_map'
require 'deploy/setup'
require 'deploy/base'
require 'deploy/remote_commands'

require 'deploy/recipes/base'
require 'deploy/recipes/protonet'
require 'deploy/recipes/padrino_data_mapper'
require 'deploy/recipes/rails'

