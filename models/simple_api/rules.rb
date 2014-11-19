require 'pp'
module SimpleApi
  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules(config).each{|rule| rule.place_to(@rules) }
      end

      def load_rules(config)
        Rule.order(:position).all.map{|item| Rule.from_param(item.sphere, item.param)[item.id] }
      end

      def connect_db(config)
      end

      def prepare_params(params)
        OpenStruct.new(JSON.load(params))
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        content = found.kind_of?(Array) ? found.try(:first).try(:content) : found.try(:content)
      end
    end
  end
end
