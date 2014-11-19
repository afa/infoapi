module SimpleApi
  module RuleDefs
    module Default
      def parse_params(param, hsh_rule)
        nil
      end

      def load_rule(rule, flt)
        nil
      end

      def like?(param, rule)
        true
      end
      module_function :parse_params, :load_rule, :like?
    end
  end
end

