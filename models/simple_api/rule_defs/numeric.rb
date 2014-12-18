module SimpleApi
  module RuleDefs
    class NumericRuleItem < ExtendedRuleItem
      attr_accessor :from, :to, :range
      def initialize(flt, cfg)
        super
        self.from = definition['min'] if definition['min']
        self.to = definition['max'] if definition['max']
        parse_config
      end

      def valid_range(first, last)
        first ||= from
        first = from if first.to_i < from.to_i
        last ||= to
        last = to if last.to_i > to.to_i
        first.to_i..last.to_i
      end

      def parse_config
        if config.kind_of? ::Numeric
          self.range = valid_range(config, config)
          return
        end
        if config.kind_of?(::String) && %w(any non-empty empty).include?(config.strip)
          self.range = 1..-1
        else
          if config.is_a?(::String)
            self.range = range_from_string(config)
          end
          if config.is_a?(::Hash)
            self.range = range_from_hash(config)
          end
          self.config = self.range.to_a.first if self.range && self.range.is_a?(Range) && self.range.size == 1
        end
      end

      def range_from_string(config)
        ary = (' ' + config + ' ').split('-').map{|item| item.blank? ? nil : item.strip }
        valid_range(ary.first, ary.last)
      end

      def range_from_hash(config)
        valid_range(config["from"] ? config["from"].to_i : nil, config["to"] ? config["to"].to_i : nil)
      end

      def fetch_list(rule)
        s = super
        return s[:data] if s[:data]
        return (range.to_a.empty? ? from..to : range).to_a unless s[:meta]
        # return (range.to_a.empty? ? from..to : range).to_a.map{|i| {filter => i} } unless s[:meta]
        [nil]
      end

      def check(param)
        return true if super
        val = JSON.load(param.data[filter]) rescue param.data[filter]
        return false if val.nil?
        return (range_from_hash(val).to_a & (range || []).to_a).present? if val.is_a?(::Hash)
        return (range_from_string(val).to_a & (range || []).to_a).present? if val.is_a?(::String)
        (val >= from.to_i && val <= to.to_i && ((range || []).include? val || val == config.to_i))
      end

      def convolution(param)
        val = JSON.load(param) rescue param
        return nil if val.nil?
        return range_from_hash(val).first.to_i if val.is_a?(::Hash) && range_from_hash(val).size == 1
        return range_from_string(val).first.to_i if val.is_a?(::String) && range_from_string(val).size == 1
        val.to_i
      end
    end
    module Numeric

      def load_rule(flt, cfg)
        SimpleApi::RuleDefs::NumericRuleItem.new(flt, cfg)
      end

      # def like?(param, tester)
      #   return tester.check(param)
      # end
      module_function :load_rule
      # , :like?
    end
  end
end
