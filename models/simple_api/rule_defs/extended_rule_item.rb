require 'open-uri'
module SimpleApi
  module RuleDefs
    class ExtendedRuleItem
      attr_accessor :definition, :config, :filter, :current_rule
      def initialize(rule, flt)
        self.filter = flt
        self.current_rule = rule
        self.definition = SimpleApi::RuleDefs::TYPES[flt]
        self.config = JSON.load(rule.filters[flt]) rescue rule.filters[flt]
      end

      def check(param)
        if config.is_a?(::String)
          return true if config == 'empty' && param.data[filter].blank?
          return true if config == 'non-empty' && param.data[filter].present?
          return true if config == 'any'
        end
        false
      end

      def load_list(list)
        fapi_prefix = CONFIG["fapi_prefix"]
        p fapi_prefix
        uri = URI.parse([fapi_prefix].tap do |bb|
          bb << current_rule.sphere
          bb << list
          bb << filter
        end.join('/'))
        p uri
        # data = JSON.load(uri.open)['attributes'] rescue []
        data = JSON.load(uri.open) rescue []
        p data
        data
      end

      def load_from_master
        if definition["fetch_list"].present?
          return load_list(definition["fetch_list"])
        end
      end

      def fetch_list
        return load_from_master if %w(any non-empty).include?(config)
        []
      end

    end
  end
end
