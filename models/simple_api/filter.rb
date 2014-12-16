module SimpleApi
  class Filter
    attr_accessor :rules, :traversal_order
    def initialize(*data)
      self.rules = {}
      hash = Hash[*data]
      hash.each do |k, v|
        rules.merge!(k => SimpleApi::RuleDefs.from_name(k).load_rule(k, v))
      end
    end

    def postprocess_init
      # convert nil to any - need?
    end

    def traversal_order=(order)
      @traversal_order = (JSON.load(order) rescue order) || []
    end

    def [](name)
      rules[name]
    end

    def to_json
      {'filter' => rules.to_json, 'traversal_order' => traversal_order.to_json} #TODO dump to json
    end

    def like?(params)
      rules.inject(true) do |rslt, (flt, tester)|
        (rslt && tester.check(params))
      end
    end

    def default?
      (rules.has_key?('default') && rule.filters['default']) || (rules.values.all?{|item| item.config == 'any' })
    end

    def write_ref(rule, root_id, hash, index)
      rule.write_ref(root_id, hash, index)
    end

    def recurse_index(flst, cur_hash, root, parent, idx, rule)
      leafs = []
      if flst.blank?
        write_ref(rule, root, cur_hash, parent)
        return [cur_hash]
      end
      wlst = flst.dup
      flt = wlst.shift
      rdef = self[flt]
      values = rdef.fetch_list(rule)
      values.each do |val|
        hsh = cur_hash.merge(flt => val)
        ix = idx.insert(json: JSON.dump(hsh), root_id: root, parent_id: parent, filter: flt, value: val, rule_id: rule.pk)
        leafs += recurse_index(wlst, hsh, root, ix, idx, rule)
      end
      leafs
    end

    def build_index(root, rule)
      idx = DB[:indexes]
      filter_list = traversal_order || []
      recurse_index(filter_list, {}, root, nil, idx, rule)
    end

  end
end
