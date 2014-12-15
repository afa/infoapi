module SimpleApi
  module AnnotationsRuleMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    def leaf_node
      []
    end

    def place_at(hash)
      point = rule_path[0..-2].inject(hash){|rslt, item| rslt[item] }
      unless point.has_key?(rule_path.last)
        point[rule_path.last] = leaf_node
      end
      point[rule_path.last] << self
    end

    module ClassMethods
      def clarify(located, params)
        located.each.take_until{|rule| rule.filters.default? }.select do |rule|
          rule.filters.like?(params)
          # rule.filters.keys.inject(true) do |rslt, flt|
          #   klass = SimpleApi::RuleDefs.from_name(flt)
          #   r_data = klass.load_rule(rule, flt)
          #   (rslt && klass.like?(params, r_data))
          # end
        end
      end
    end
  end
end
