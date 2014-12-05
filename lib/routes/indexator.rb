require 'json'
require 'simple_api/index'
module Sinatra
  module Custom
    module Routing
      module Indexator
        def self.registered(app)
          index_page = lambda do |sphere|
            SimpleApi::Index.roots
          end
          concrete_index = lambda do |sphere, rule_selector, rule_params|
            SimpleApi::Index.tree(sphere, rule_selector, rule_params)
          end
          app.get '/api/v1/:sphere/index', &index_page
          app.get '/api/v1/:sphere/index/:rule_selector/*', &concrete_index
        end
      end
    end
  end
end
