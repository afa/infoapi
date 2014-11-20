module SimpleApi
  module RuleDefs
    class ExtendedRuleItem
      attr_accessor :definition, :config, :filter
      def initialize(rule, flt)
        self.filter = flt
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

      def fetch_list
        []
      end

    end
  end
end
