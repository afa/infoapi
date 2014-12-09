module SimpleApi
  class Index
    class << self
      def roots(sphere)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first.tap{|x| p x }.try(:[], :id)
        JSON.dump(next: SimpleApi::Rule.where(sphere: sphere).where('traversal_order is not null').order(:position).all.select{|r| (JSON.load(r.traversal_order) rescue []).present? }.map{|r| {name: r.name, url:"/en/#{sphere}/index/rating,#{r.name}"} } )
      end

      def tree(sphere, rule_selector, rule_params, params)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first.tap{|x| p x }.try(:[], :id)
        selector = rule_selector.strip.split(',')
        p selector
        p rule_params
        p params
        rat = selector.shift
        return roots(sphere) unless 'rating' == rat
        if selector.empty?
          return roots(sphere)
        end
        lang = "en"
        name = selector.shift
        return roots(sphere) unless name.present?
        return roots(sphere) unless rule = Rule.where(name: name).first
        fields = selector || []
        leaf_page(root, rule, name, selector, params)
       end

      def index_page(root)
        JSON.dump(DB[:indexes].where(root_id: root, parent_id: nil).all)
      end

      # def root_page
      #   '[]'
      # end

      def leaf_page(root, rule, name, selector, params)
        idx = DB[:indexes]
        parent = nil
        lded = JSON.load(params["p"]) rescue params['p']
        lded ||= {}
        hash = {}
        hash.merge!('criteria' => lded.delete('criteria')) if lded.has_key?('criteria')
        hash.merge!(lded["filters"]) if lded.has_key?('filters')
        curr = {id: nil} #idx.where(root_id: root, rule_id: rule.pk, parent_id: nil).all.tap{|x| p 'x', x }.first
        # curr = idx.where(root_id: root, rule_id: rule.pk, parent_id: nil).all.tap{|x| p 'x', x }.first
        return '[]' unless curr

        bcr = []
        # bcr << {curr[:filter] => curr[:value]}
        selector.each do |fname|
          parent = curr
          p rule, parent, fname, hash
          curr = idx.where(root_id: root, rule_id: rule.pk, parent_id: parent[:id], filter: fname, value: hash[fname]).first
          p curr
          break unless curr
          bcr << {curr[:filter] => curr[:value]}
        end
        return '[]' unless curr
        nxt = idx.where(root_id: root, rule_id: rule.pk, parent_id: curr[:id]).all
        rsp = {}
        if nxt.present?
          rsp['next'] = nxt.map do |item|
          sel = bcr + [{item[:filter] => item[:value]}]
          parm = mk_params(sel)
          p 'sel', sel, sel.map{|s| s.keys }.flatten
            {
              'name' => item[:filter],
              'url' => "/en/#{DB[:roots].where(id: root).first[:sphere]}/index/#{ ([(['rating', name] + parm[:list]).join(',')] + parm[:path]).join('/') }"
            }
          end
        end
        JSON.dump(rsp)
      end

      def mk_params(sel)
        slctr = sel.dup
        # opts = p.dup
        # flts = p["filter"] || {}
        crit = slctr.select do |hash|
          hash.keys.include? 'criteria'
        end
        slctr.delete_if do |hash|
          hash.keys.include? 'criteria'
        end
        slctr.sort_by{|i| i.keys.first }
        data = []
        list = []
        list << 'criteria' unless crit.blank?
        data << 'criteria' unless crit.blank?
        data << crit.first.values.first if crit.present? && crit.first.values.first.present?
        data << 'filters' if slctr.present? && slctr.detect{|h| h.values.first.present? }
        slctr.each do |hsh|
          list << hsh.keys.first
          data << hsh.keys.first if hsh.values.first.present?
          data << hsh.values.first if hsh.values.first.present?
        end
        {list: list, path: data}
      end

    end
  end
end
