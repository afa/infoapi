module SimpleApi
  module AnnotationsRuleMethods
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
  end
end
