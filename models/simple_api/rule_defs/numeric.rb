module SimpleApi
  module RuleDefs
    class NumericRuleItem < ExtendedRuleItem
      attr_accessor :from, :to, :range
      def initialize(rule, flt)
        super
        self.from = definition['min'] if definition['min']
        self.to = definition['max'] if definition['max']
        parse_config
      end

      def valid_range(first, last)
        first ||= from
        first = from if first.to_i < from
        last ||= to
        last = to if last.to_i > to
        self.range = first.to_i..last.to_i
      end

      def parse_config
        if config.kind_of? ::Numeric
          valid_range(config, config)
          return
        end
        if %w(any non-empty empty).include?(config.strip)
          self.range = 1..-1
        else
          ary = (' ' + config + ' ').split('-').map{|item| item.blank? ? nil : item.strip }
          valid_range(ary.first, ary.last)
        end
      end

      def check(param)
        return true if super
        val = JSON.load(param.data[filter]) rescue param.data[filter]
        return false if val.nil?
        (val >= from && val <= to && (range.include? val || val == config)).tap{|x| p "check result", x}
      end
    end
    module Numeric

      def load_rule(rule, flt)
        tester = SimpleApi::RuleDefs::NumericRuleItem.new(rule, flt)
      end

      def like?(param, tester)
        return tester.check(param)
      end
      module_function :load_rule, :like?
    end
  end
end
