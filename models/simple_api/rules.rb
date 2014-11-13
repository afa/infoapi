require 'pp'
module SimpleApi
  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules(config).each{|rule| puts rule.class.name, rule.id; rule.place_to(@rules) }
      end

      def load_rules(config)
        # connect_db 
        # Sequel.postgres(config['db'].inject({}){|r, (k, v)| r.merge(k.to_sym => v) }) do |db|
        Rule.order(:id).all.map{|item| p Rule.from_param(item.sphere, item.param); p Rule.from_param(item.sphere, item.param)[item.id].class; Rule.from_param(item.sphere, item.param)[item.id] } #.new(item.to_hash) }
        # end
      end

      def connect_db(config)
        # DB = Sequel.postgres(config['db'].inject({}){|r, (k, v)| r.merge(k.to_sym => v) })
        # Sequel::Model.db = DB
        p Sequel::Model.db
      end

      def prepare_params(params)
        OpenStruct.new(JSON.load(params))
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        # logger.info "found #{found.inspect}"
        content = found.kind_of?(Array) ? found.try(:first).try(:content) : found.try(:content)
      end
    end
  end
end
