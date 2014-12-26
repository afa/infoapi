module SimpleApi
  class Index
    class << self
      def breadcrumbs(sphere, param, params)
        JSON.dump({breadcrumbs: nil})
      end

      def roots(sphere, param)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first
        # refactor for range limiting
        JSON.dump(
          {
          next: SimpleApi::Rule.where(sphere: sphere, param: param).where('traversal_order is not null').order(:position).all.select{|r| (JSON.load(r.traversal_order) rescue []).present? }.map do |r|
            content = json_load(r.content, {})
            {
              name: r.name,
              label: (content['index'] || content['h1'] || r.name),
              links: DB[:object_data_items].where(rule_id: r.pk, index_id: nil).all.map{|o| {label: o[:label], url: o[:url], photo: o[:photo]} }.uniq.sample(4).shuffle.map do |obj|
                {
                  name: obj[:label],
                  url: obj[:url],
                  photo: obj[:photo]
                }
              end,
              url:"/en/#{sphere}/index/#{param.to_s},#{r.name}"
            }
          end
          }.tap{|x| x[:total] = x[:next].size }
        )
      end

      def tree(sphere, rule_selector, rule_params, params)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first[:id]
        selector = rule_selector.strip.split(',')
        rat = selector.shift
        # return roots(sphere) unless 'rating' == rat
        if selector.empty?
          return roots(sphere, rat)
        end
        lang = "en"
        name = selector.shift
        return roots(sphere, rat) unless name.present?
        return roots(sphere, rat) unless rule = Rule.where(name: name, param: rat).first
        fields = selector || []
        leaf_page(root, rule, name, selector, params, rat)
       end


      def index_links(bcr, curr, route)
        sel = bcr # + [{item[:filter] => item[:value]}]
        rul = SimpleApi::Rule[curr[:rule_id]]
        url = route.route_to(rul.param, sel.inject({}){|r, h| r.merge(h) })
        links = DB[:refs].where(index_id: curr[:id], is_empty: false, duplicate_id: nil).all
        if links.present?
          links.map do |ref|
            lbl = JSON.load(SimpleApi::Rule[ref[:rule_id]][:content])['h1']
            photo = DB[:object_data_items].where(index_id: ref[:index_id]).all.map{|o| o[:photo] }.shuffle.first
            {
              label: lbl,
              photo: photo,
              url: ref[:url]
            }
          end
              # links: DB[:object_data_items].where(rule_id: r.pk, index_id: nil).all.map{|o| {label: o[:label], url: o[:url], photo: o[:photo]} }.uniq.sample(4).shuffle.map do |obj|
              #   {
              #     name: obj[:label],
              #     url: obj[:url],
              #     photo: obj[:photo]
              #   }
              # end,
        else
          '[]'
        end
      end

      def leaf_page(root, rule, name, selector, params, param)
        range = 0..99
        idx = DB[:indexes]
        parent = nil
        lded = JSON.load(params['p']) rescue params['p']
        lded ||= {}
        hash = {}
        range = lded['offset']..(lded['offset']-1) if lded['offset']
        range = range.first..(lded['limit']-1+range.first) if lded['limit']
        sphere = DB[:roots].where(id: root).first[:sphere]
        route = SimpleApiRouter.new('en', sphere)
        hash.merge!('criteria' => lded.delete('criteria')) if lded.has_key?('criteria')
        hash.merge!(lded["filters"]) if lded.has_key?('filters')
        curr = {id: nil}

        bcr = []
        selector.each do |fname|
          parent = curr
          flt = SimpleApi::RuleDefs.from_name(fname).load_rule(fname, hash[fname])
          curr = idx.where(root_id: root, rule_id: rule.pk, parent_id: parent[:id], filter: fname, value: flt.convolution(hash[fname]).to_s).first
          break unless curr
          bcr << {curr[:filter] => curr[:value]}
        end
        unless curr
          return JSON.dump({'ratings' => index_links(bcr, parent, route)})
        end
        nxt = idx.where(root_id: root, rule_id: rule.pk, parent_id: curr[:id]).all
        rsp = {}
        if nxt.present?
          rsp['next'] = nxt[range].map do |item|
            sel = bcr + [{item[:filter] => item[:value]}]
            spath = sel.map{|i| i.keys.first }.join(',')
            parm = route.route_to("index/#{[rule.param, name, sel.blank? ? nil : sel.map{|i| i.keys.first }].compact.join(',')}", sel.inject({}){|r, i| r.merge(i) })
            {
              'label' => "#{item[:filter]}:#{item[:value]}",
              'name' => item[:filter],
              'url' => parm,
              'links' => next_links(item[:id])
            }
          end
          rsp['total'] = nxt.size
        end
        rsp['ratings'] = index_links(bcr, curr, route)
        rsp['ratings_total'] = DB[:refs].where(index_id: curr[:id], is_empty: false, duplicate_id: nil).count
        JSON.dump(rsp)
      end

      def next_links(id)
        DB[:object_data_items].where(index_id: id).all.sample(4).map do |lnk|
          {
            'name' => lnk[:label],
            'url' => lnk[:url],
            'photo' => lnk[:photo]
          }
        end
      end

      # def mk_params(sel)
      #   slctr = sel.dup
      #   # opts = p.dup
      #   # flts = p["filter"] || {}
      #   crit = slctr.select do |hash|
      #     hash.keys.include? 'criteria'
      #   end
      #   slctr.delete_if do |hash|
      #     hash.keys.include? 'criteria'
      #   end
      #   slctr.sort_by{|i| i.keys.first }
      #   data = []
      #   list = []
      #   list << 'criteria' unless crit.blank?
      #   data << 'criteria' unless crit.blank?
      #   data << crit.first.values.first if crit.present? && crit.first.values.first.present?
      #   data << 'filters' if slctr.present? && slctr.detect{|h| h.values.first.present? }
      #   slctr.each do |hsh|
      #     list << hsh.keys.first
      #     data << hsh.keys.first if hsh.values.first.present?
      #     data << hsh.values.first if hsh.values.first.present?
      #   end
      #   {list: list, path: data}
      # end

    end
  end
end
