require 'json'
require 'simple_api/index'
module Sinatra
  module Custom
    module Routing
      module Rules
        def self.registered(app)
          index = lambda do |sphere|
            ::JSON.dump(SimpleApi::Rules.rule_list(sphere: sphere))
            # SimpleApi::Index.roots(sphere, 'group')
          end
          item = lambda do |sphere, id|
            ::JSON.dump(SimpleApi::Rules.rule_item(id))
            # SimpleApi::Index.tree(sphere, rule_selector, rule_params, params)
          end
          app.get '/api/v1/:sphere/rules/:id', &item
          app.get '/api/v1/:sphere/rules/', &index
          app.get '/api/v1/:sphere/rules', &index
        end
      end
    end
  end
end

