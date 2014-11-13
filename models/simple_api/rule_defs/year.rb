module SimpleApi
  module RuleDefs
    module Year
      def parse_params(param, hsh_rule)
        hsh_rule.keys.inject({}){|rslt, name| rslt.merge(name => param.data[name].to_i) }
      end

      def load_rule(rule)
        names = rule.extended['year']

        names.inject({}){|rslt, name| p rule.filters.class; rslt.merge( name => convert(rule.filters[name]) ) }
      end

      def convert(str)
        return str.strip if %w(any non-empty empty).include?(str.strip)
        rslt = (' ' + str + ' ').split('-').map{|item| item.blank? ? nil : item.strip.to_i }
        rslt.first = 1900 if rslt.first.nil?
        rslt.last = Date.today.year + 1 if rslt.last.nil?
        Range.new(rslt.first, rslt.last).to_a
      end

      def like?(param, rule)
        p "like", param, rule
        if rule.kind_of?(String)
          return true if rule == 'any'
          return true if param.blank? && rule == 'empty'
          return true if !param.blank? && rule == 'non-empty'
          return false
        end
        if rule.kind_of?(Array)
          return param.is_a?(Array) ? (param & rule).present? : rule.include?(param)
        end
      end
      module_function :parse_params, :load_rule, :convert, :like?
    end
  end
end
