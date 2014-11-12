module SimpleApi
  module RuleDefs
    module Year
      def parse_params(p)
        p p
        p
      end

      def load_rule(rule)
        convert(rule.filter['year'])
      end

      def convert(str)
        return str.strip if %w(any non-empty empty).include?(str.strip)
        rslt = (' ' + str + ' ').split('-').each{|item| item.blank? ? nil : item.strip.to_i }
        rslt.first = 1900 if rslt.first.nil?
        rslt.last = Date.today.year + 1 if rslt.last.nil?
        Range.new(rslt.first, rslt.last).to_a
      end

      def like?(param, rule)
        if rule.kind_of?(String)
          return true if rule == 'any'
          return true if param.blank? && rule == 'empty'
          return true if !param.blank? && rule == 'non-empty'
          return false
        end
        if rule.kind_of?(Array)
          return param.is_a?(Array?) ? (param & rule).present? : rule.include?(param)
        end
      end
      module_function :parse_params, :load_rule, :convert, :like?
    end
  end
end
