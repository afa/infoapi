require 'pp'
module SimpleApi
  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules(config).each{|rule| rule.place_to(@rules) }
      end

      def load_rules(config)
        # connect_db 
        Sequel.postgres(config['db'].inject({}){|r, (k, v)| r.merge(k.to_sym => v) }) do |db|
          db[:rules].order(:id).all.map{|item| Rule.from_param(item[:sphere], item[:param]).new(item) }
        end
      end

      def connect_db
        Sequel::Model.db = Sequel.postgres(config['db'].inject({}){|r, (k, v)| r.merge(k.to_sym => v) })
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
