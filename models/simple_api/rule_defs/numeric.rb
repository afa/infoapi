module SimpleApi
  module RuleDefs
    module Numeric
      def parse_params(p)
        p p
        p
      end

      def load_rule(rule)
        convert(rule.filter['year'])
      end

      def convert(str)
        return str.strip if %w(any non-empty empty).include?(str.strip)
        str.strip.to_i
      end

      def like?(param, rule)
        if rule.kind_of?(String)
          return true if rule == 'any'
          return true if param.blank? && rule == 'empty'
          return true if !param.blank? && rule == 'non-empty'
          return false
        end
        if rule.kind_of?(Numeric)
          return param == rule
        end
        if rule.kind_of?(Array)
          return param.is_a?(Array?) ? (param & rule).present? : rule.include?(param)
        end
      end
      module_function :parse_params, :load_rule, :convert, :like?
    end
  end
end

