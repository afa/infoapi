require 'json'
require 'simple_api/index'
module Sinatra
  module Custom
    module Routing
      module Rules
        def self.registered(app)
          index = lambda do
            SimpleApi::Rules.rule_list(param)
            # SimpleApi::Index.roots(sphere, 'group')
          end
          item = lambda do |id|
            SimpleApi::Rules.rule_item(id)
            # SimpleApi::Index.tree(sphere, rule_selector, rule_params, params)
          end
          app.get '/api/v1/rules/:id', &item
          app.get '/api/v1/rules/', &index
          app.get '/api/v1/rules', &index
        end
      end
    end
  end
end

