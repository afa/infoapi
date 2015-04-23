module SimpleApi
  class DesignRule < Rule
    def self.clarify(located, params)
      located[params.design] || located['std']
    end

    def rule_path
      super << design
    end

    def leaf_node
      {}
    end

    def place_at(hash)
      point = rule_path[0..-2].inject(hash){|rslt, item| rslt[item] }
      point[rule_path.last] = self
    end
  end
end
