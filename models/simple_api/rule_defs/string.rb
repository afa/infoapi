module SimpleApi
  module RuleDefs
    class StringRuleItem < ExtendedRuleItem
      attr_accessor :string, :array
      def initialize(rule, flt)
        super
        parse_config
      end

      def parse_config
        if config.kind_of? ::Array
          self.array = config
          return
        end
        self.array = []
        self.string = config.strip
      end

      def check(param)
        return true if super
        val = JSON.load(param.data[filter]) rescue param.data[filter]
        return false if val.nil?
        array.include? val || val == string
      end
    end

    module String
      def load_rule(rule, flt)
        tester = SimpleApi::RuleDefs::StringRuleItem.new(rule, flt)
      end

      def like?(param, tester)
        return tester.check(param)
      end
      module_function :load_rule, :like?
      # :parse_params, , :convert
    end
  end
end
