module SimpleApi
  module RuleDefs
    class StringRuleItem < ExtendedRuleItem
      attr_accessor :string, :array
      def initialize(flt, data)
      # def initialize(rule, flt)
        super
        parse_config
      end

      def fetch_list(rule)
        s = super
        return s[:data] if s[:data]
        # return (array.empty? ? [string] : array).map{|i| {filter => i} } unless s[:meta]
        return (array.empty? ? [string] : array) unless s[:meta]
        return [nil]
      end

      def parse_config
        if config.kind_of? ::Array
          self.array = config
          return
        end
        unless %w(any empty non-empty).include?(config)
        self.string = config.strip
        self.array = [string]
        end
      end

      def check(param)
        return true if super
        val = JSON.load(param.data[filter]) rescue param.data[filter] # val is request
        return false if val.nil?
        return true if val.kind_of?(::Array) && ((val & (array || []) == val) || ([string] == val))
        return true if val.kind_of?(::String) && ((val == string) || ((array || []).include?(val)))
        false
      end

      def convolution(param)
        val = JSON.load(param) rescue param
        return nil if val.nil?
        return val.first if val.is_a?(::Array) && val.size == 1
        val.to_s
      end
    end

    module String
      def load_rule(flt, cfg)
        SimpleApi::RuleDefs::StringRuleItem.new(flt, cfg)
      end

      def like?(param, tester)
        tester.check(param)
      end
      module_function :load_rule, :like?
    end
  end
end
