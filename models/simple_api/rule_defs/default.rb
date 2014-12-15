module SimpleApi
  module RuleDefs
    class DefaultRuleItem < ExtendedRuleItem
      def initialize(rule, flt)
        super
      end

      def fetch_list(rule)
        # super
        [nil]
      end

    end
    module Default
      def parse_params(param, hsh_rule)
        nil
      end

      def load_rule(rule, flt)
        SimpleApi::RuleDefs::DefaultRuleItem.new(rule, flt)
      end

      # def like?(param, rule)
      #   true
      # end
      module_function :parse_params, :load_rule
      # , :like?
    end
  end
end

