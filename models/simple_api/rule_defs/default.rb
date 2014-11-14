module SimpleApi
  module RuleDefs
    module Default
      def parse_params(param, hsh_rule)
        nil
      end

      def load_rule(rule)
        nil
      end

      # def convert(str)
      #   return str.strip if %w(any non-empty empty).include?(str.strip)
      #   rslt = (' ' + str + ' ').split('-').map{|item| item.blank? ? nil : item.strip.to_i }
      #   rslt.first.present? && rslt.last.present? ? Range.new(rslt.first, rslt.last).to_a : (rslt.first.present? ? {from: rslt.first} : {}).merge(rslt.last.present? ? {to: rslt.last} : {})
      # end

      def like?(param, rule)
        true
      end
      module_function :parse_params, :load_rule, :like?
    end
  end
end

