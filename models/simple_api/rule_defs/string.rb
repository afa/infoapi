module SimpleApi
  module RuleDefs
    class StringRuleItem < ExtendedRuleItem
      attr_accessor :string, :array
      def initialize(rule, flt)
        super
        parse_config
      end

      def fetch_list
        array.empty? ? [string] : array
      end

      def parse_config
        if config.kind_of? ::Array
          self.array = config
          return
        end
        self.string = config.strip
        self.array = [string]
      end

      def check(param)
        return true if super
        val = JSON.load(param.data[filter]) rescue param.data[filter] # val is request
        return false if val.nil?
        return true if val.kind_of?(::Array) && ((val & array  == val) || ([string] == val))
        return true if val.kind_of?(::String) && ((val == string) || (array.include?(val)))
        false
      end
    end

    module String
      def load_rule(rule, flt)
        SimpleApi::RuleDefs::StringRuleItem.new(rule, flt)
      end

      def like?(param, tester)
        tester.check(param)
      end
      module_function :load_rule, :like?
      # :parse_params, , :convert
    end
  end
end
