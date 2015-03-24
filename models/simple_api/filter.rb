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
      (rules.has_key?('default') && self['default']) || (rules.values.all?{|item| item.config == 'any' })
    end

    def write_ref(rule, root, hash, index)
      rule.write_ref(root, hash, index)
    end

    def recurse_index(flst, cur_hash, root, parent, rule)
      whash = cur_hash.dup
      whash.merge!('catalog' => whash.delete('path')) if whash.has_key?('path')
      leafs = []
      if flst.blank?
        # write_ref(rule, root, whash, parent)
        return [whash]
      end
      wlst = flst.dup
      flt = wlst.shift
      flt = 'catalog' if flt == 'path'
      rdef = self[flt]
      rdef = self['path'] if flt == 'catalog' && self['path']
      values = rdef.fetch_list(rule)
      route = SimpleApiRouter.new(rule.lang, rule.sphere)
      values.each do |val|
        leaf = wlst.empty?
        hsh = whash.merge(flt => val)
        sel = rule.filters.traversal_order[0..(-hsh.size + 1)].map{|n| n == 'path' ? 'catalog' : n }
        h = hsh.dup
        h.delete_if{|k, v| !sel.include?(k) } #!!
        ix = SimpleApi::Sitemap::Index.insert(json: JSON.dump(h), rule_id: rule.pk, root_id: root.pk, parent_id: parent, filter: flt, value: val, url: route.route_to("index/#{[rule.param, rule.name, sel.blank? ? nil : sel].compact.join(',')}", h), label: "#{flt}:#{val}", leaf: leaf)
        # ix = SimpleApi::Sitemap::Index.insert(json: JSON.dump(hsh), rule_id: rule.pk, root_id: root.pk, parent_id: parent, filter: flt, value: val, url: route.route_to("index/#{[rule.param, rule.name, sel.blank? ? nil : sel].compact.join(',')}", hsh), label: "#{flt}:#{val}")
        leafs += recurse_index(wlst, hsh, root, ix, rule)
      end
      leafs
    end

    # def build_junk(rule)
    #   junk = []
    #   ars = []
    #   order = json_load(traversal_order, traversal_order)
    #   order.each do |flt|
    #     flt = 'catalog' if flt == 'path'
    #     rdef = self[flt]
    #     rdef = self['path'] if flt == 'catalog' && self['path']
    #     values = rdef.fetch_list(rule)
    #     keyz = [flt] * values.size
    #     ars << keyz.zip(values).map{|a| Hash[*a] }
    #   end
    #   return [] if ars.empty? 
    #   junk += ars.shift
    #   while ars.present?
    #     junk = junk.product(ars.shift).map(&:flatten)
    #   end
    #   rslt = junk.map do |ah|
    #     ah.inject({}){|r, h| r.merge(h.is_a?(Hash) ? h : Hash[*h]) }
    #   end
    #   rslt.each{|h| write_ref(rule, OpenStruct.new(sitemap_session_id: nil), h, nil) }
    # end

    def build_index(root, rule)
      parent = SimpleApi::Sitemap::Index.where(root_id: root.pk, rule_id: rule.pk, url:"/en/#{root.sphere}/index/#{root.param},#{rule.name}").first
      filter_list = traversal_order || []
      recurse_index(filter_list, {}, root, parent.pk, rule)
    end

  end
end
