module SimpleApi
  class Index
    class << self
      def breadcrumbs(sphere, param, params)
        lded = json_load(params['p'], params['p'])
        lded ||= {}
        hash = {}
        hash.merge!('criteria' => lded.delete('criteria')) if lded.has_key?('criteria')
        hash.merge!(lded.delete("filters")) if lded.has_key?('filters')
        route = SimpleApiRouter.new(:en, sphere)
        rules = SimpleApi::Rule.where(sphere: sphere, param: param).order(%i(position id)).all
        rat = SimpleApi::Sitemap::Reference.where(is_empty: false, rule_id: rules.map(&:pk), url: route.route_to('rating', hash.dup)).first
        return JSON.dump({breadcrumbs: nil}) unless rat
        idx = rat.super_index || rat.index
        JSON.dump({breadcrumbs: idx.try(:breadcrumbs)})
      end

      def rules(sphere, param, rule, rng, r_rng)
        root = SimpleApi::Sitemap::Root.reverse_order(:id).where(sphere: sphere).first
        nxt = rule.indexes_dataset.where(parent_id: nil, root_id: root.pk).offset(rng.first).limit(rng.size).all
        p 'rules'
        p nxt.size
        p nxt.first
        # refactor for range limiting
        route = SimpleApiRouter.new('en', sphere)
        rtngs = index_links(nil, route, 'rating', rule, r_rng)
        rsp = {
            breadcrumbs: rule.breadcrumbs,
            # next: SimpleApi::Rule.where(sphere: sphere, param: param).where('traversal_order is not null').order(:position).all.select{|r| json_load(r.traversal_order, []).present? }.map do |r|
            next: nxt.map do |r|
              # content = json_load(r.content, {})
              {
                name: r.filter,
                label: r.label,  #(content['index'] || content['h1'] || r.name),
                url: r.url, #"/en/#{sphere}/index/#{param.to_s},#{r.name}",
                links: next_links(r)
                # links: r.objects_dataset.where(index_id: r.pk).all.map{|o| {name: o.label, url: o.url, photo: o.photo} }.uniq.sample(4).shuffle
              }
            end
          }.tap{|x| x[:total] = x[:next].size }
        p 'rtngs', rtngs
        rsp['ratings'] = rtngs #[r_range]
        rsp.delete('ratings') unless rsp['ratings'].present?
        if rsp['ratings'].present?
          rsp.delete('next')
          rsp.delete('total')
          rsp['total_ratings'] = rtngs.size
        end
        JSON.dump(rsp)

      end

      def roots(sphere, param)
        root = SimpleApi::Sitemap::Root.reverse_order(:id).where(sphere: sphere).first
        # refactor for range limiting
        JSON.dump(
          {
            breadcrumbs: root.breadcrumbs,
            next: SimpleApi::Rule.where(sphere: sphere, param: param).where('traversal_order is not null').order(:position).all.select{|r| json_load(r.traversal_order, []).present? }.map do |r|
              content = json_load(r.content, {})
              {
                name: r.name,
                label: (content['index'] || content['h1'] || r.name),
                url:"/en/#{sphere}/index/#{param.to_s},#{r.name}",
                links: r.objects_dataset.where(index_id: nil).all.map{|o| {name: o.label, url: o.url, photo: o.photo} }.uniq.sample(4).shuffle
              }
            end
          }.tap{|x| x[:total] = x[:next].size }
        )
      end

      def tree(sphere, rule_selector, rule_params, params)
        range = 0..99
        r_range = 0..99
        lded = json_load(params['p'])
        lded ||= {}
        hash = {}
        range = lded['offset']..(lded['offset'] + range.last - range.first) if lded['offset']
        range = range.first..(lded['limit'] - 1 + range.first) if lded['limit']
        r_range = lded['offset_ratings']..(lded['offset_ratings'] + r_range.last - r_range.first) if lded['offset_ratings']
        r_range = r_range.first..(lded['limit_ratings'] - 1 + r_range.first) if lded['limit_ratings']
        root = SimpleApi::Sitemap::Root.reverse_order(:id).where(sphere: sphere).first
        selector = rule_selector.strip.split(',')
        rat = selector.shift
        # return roots(sphere) unless 'rating' == rat
        if selector.empty?
          return roots(sphere, rat)
        end
        lang = "en"
        name = selector.shift
        return roots(sphere, rat) unless name.present?
        return roots(sphere, rat) unless rule = SimpleApi::Rule.where(name: name, param: rat, sphere: sphere).first
        fields = selector || []
        return rules(sphere, rat, rule, range, r_range) if fields.empty?
        leaf_page(root, rule, name, selector, params, rat)
       end


      def index_links(curr, route, param, rule, range)
        # sel = bcr # + [{item[:filter] => item[:value]}]
        # rul = curr.rule
        # rul = SimpleApi::Rule[curr[:rule_id]]
        # index_ids = SimpleApi::Sitemap::Index.where(parent_id: curr[:id]).all.map(&:pk)
        # if curr[:id]
        p 'indexlinks'
        if curr && curr.children_dataset.count > 0
        cnt = SimpleApi::Sitemap::ObjectData.select(:object_data_items__id, :object_data_items__index_id, Sequel.function(:random).as(:random), :object_data_items__photo, :refs__url, :refs__rule_id, :refs__json).distinct(:object_data_items__index_id).join(:indexes, indexes__id: :object_data_items__index_id).join(:refs, indexes__id: :refs__index_id).where(refs__is_empty: false, refs__super_index_id: curr.try(:pk)).count
        p 'icnt', cnt
        chld = SimpleApi::Sitemap::ObjectData.select(:object_data_items__id, :object_data_items__label, :object_data_items__index_id, Sequel.function(:random).as(:random), :object_data_items__photo, :refs__url, :refs__rule_id, :refs__json).distinct(:object_data_items__index_id).join(:indexes, indexes__id: :object_data_items__index_id).join(:refs, indexes__id: :refs__index_id).where(refs__is_empty: false, refs__super_index_id: curr.try(:pk)).offset(range.first).limit(range.size).all
        else
        cnt = SimpleApi::Sitemap::ObjectData.select(:object_data_items__id, :object_data_items__index_id, Sequel.function(:random).as(:random), :object_data_items__photo, :refs__url, :refs__rule_id, :refs__json).distinct(:object_data_items__index_id).join(:indexes, indexes__id: :object_data_items__index_id).join(:refs, indexes__id: :refs__index_id).where(refs__is_empty: false, refs__super_index_id: nil, refs__rule_id: curr.rule_id).count
        p 'icnt', cnt
        chld = SimpleApi::Sitemap::ObjectData.select(:object_data_items__id, :object_data_items__label, :object_data_items__index_id, Sequel.function(:random).as(:random), :object_data_items__photo, :refs__url, :refs__rule_id, :refs__json).distinct(:object_data_items__index_id).join(:indexes, indexes__id: :object_data_items__index_id).join(:refs, indexes__id: :refs__index_id).where(refs__is_empty: false, refs__super_index_id: nil, refs__rule_id: curr.rule_id).offset(range.first).limit(range.size).all
        end
        chld.map do |ref|
          # links = SimpleApi::Sitemap::Reference.where(super_index_id: curr[:id], is_empty: false).all

        # else
        #   links = SimpleApi::Sitemap::Reference.where(super_index_id: nil, rule_id: rul.pk, is_empty: false).all
        # end
        # url = route.route_to(param, sel.inject({}){|r, h| r.merge(h) })
        # if links.present?
        #   links.select{|r| !r.index.try(:objects_dataset).try(:empty?) }.map do |ref|
            # photo = ref.index.objects.sample.try(:photo) #check for null obj
            # if photo
              # lbl = tr_h1_params(json_load(ref.rule.content, {})['h1'], json_load(ref.json, {}))
              {
                label: ref.label,
                photo: ref.photo,
                url: ref.url
              }
            # else
            #   {}
            # end
          # end
        # else
          # []
        # end
        end
      end

      def leaf_page(root, rule, name, selector, params, param)
        range = 0..99
        r_range = 0..99
        parent = nil
        lded = json_load(params['p'])
        # lded = json_load(params['p'], params['p'])
        lded ||= {}
        hash = {}
        range = lded['offset']..(lded['offset'] + range.last - range.first) if lded['offset']
        range = range.first..(lded['limit'] - 1 + range.first) if lded['limit']
        r_range = lded['offset_ratings']..(lded['offset_ratings'] + r_range.last - r_range.first) if lded['offset_ratings']
        r_range = r_range.first..(lded['limit_ratings'] - 1 + r_range.first) if lded['limit_ratings']
        sphere = root.sphere
        route = SimpleApiRouter.new('en', sphere)
        hash.merge!('criteria' => lded.delete('criteria')) if lded.has_key?('criteria')
        hash.merge!(lded["filters"]) if lded.has_key?('filters')
        hash.delete_if{|k, v| !selector.include?(k) }
        hash.merge!('catalog' => hash.delete("path")) if hash.has_key?('path')
        # curr = {id: nil, rule_id: rule.pk}

        p selector
        ccr = route.route_to((["index/#{param}", rule.name] + selector).join(','), hash)
        p ccr
        curr = SimpleApi::Sitemap::Index.where(url: ccr).first
        # bcr = []
        # cselector = selector.dup
        # loop do
        #   break if cselector.blank?
        #   fname = cselector.shift
        #   fname = 'catalog' if fname == 'path'
        #   parent = curr
        #   flt = SimpleApi::RuleDefs.from_name(fname).load_rule(fname, hash[fname])
        #   curr = rule.indexes_dataset.where(root_id: root.pk, parent_id: parent[:id], filter: fname, value: flt.convolution(hash[fname]).to_s).first
        #   unless curr
        #     if cselector.present?
        #       puts "skipable #{fname}-#{hash[fname]}"
        #       pfname = [fname]
        #       pval = [flt.convolution(hash[fname])]
        #       cname = []
        #       cval = []
        #       cselector.each do |nm|
        #         nm = 'catalog' if nm == 'path'
        #         cname << nm
        #         f = SimpleApi::RuleDefs.from_name(nm).load_rule(nm, hash[nm])
        #         cval << f.convolution(hash[nm])
        #         curr = rule.indexes_dataset.where(root_id: root.pk, parent_id: parent[:id], filter: JSON.dump(pfname + cname), value: JSON.dump(pval + cval)).first
        #         break if curr
        #       end
        #       cselector.shift(cname.size) if curr
        #     end
        #     break unless curr
        #   end
        #   bcr << {json_load(curr.filter, curr.filter) => json_load(curr.value, curr.value)}
        # end
        rsp = {}
        p 'curr-err?', curr
        return rules(sphere, root.param, rule) unless curr
          # rtngs = index_links({id: nil, rule_id: rule.pk}, route, 'rating')
          # rsp['ratings'] = rtngs[r_range]
          # rsp['total_ratings'] = rtngs.size
          # return JSON.dump({'ratings' => rtngs[r_range], 'total_ratings' => rtngs.size})
        # end
        # nxt = rule.indexes_dataset.where(root_id: root.pk, parent_id: curr[:id]).all.select{|n| next_links(n).present? }
        # nxt = curr.children.select{|n| next_links(n).present? }
        # nxt = curr.children_dataset.select(:id.distinct).join(:object_data_items, index_id: :id).all.map(&:reload) #select{|n| next_links(n).present? }
        nxt_size = curr.children_dataset.select(:indexes__id).join(:object_data_items, index_id: :id).distinct(:indexes__id).count
        nxt = curr.children_dataset.select(:indexes__id).join(:object_data_items, index_id: :id).distinct(:indexes__id).offset(range.first).limit(range.size).map(&:reload)
        p 'leaf', nxt_size, nxt.first
        # nxt = curr.children_dataset.join(:object_data_items, index_id: :id).map{|m| SimpleApi::Sitemap::Index[m[:index_id]] }.uniq
        if nxt.present?
          rsp['next'] = nxt.map do |item|
            # sel = []
            # (bcr + [{json_load(item.filter, item.filter) => json_load(item.value, item.value)}]).map do |i|
            #   if i.keys.first.is_a? ::Array
            #     i.keys.first.zip(i.values.first)
            #   else
            #     [i.keys.first, i.values.first]
            #   end
            # end.flatten.each_slice(2){|a, b| sel << Hash[a, b] }
            # spath = sel.map{|i| i.keys.first }.join(',')
            # parm = route.route_to("index/#{[rule.param, name, sel.blank? ? nil : sel.map{|i| i.keys.first }].compact.join(',')}", sel.inject({}){|r, i| r.merge(i) })
            {
              'label' => item.label,
              'name' => item.filter,
              'url' => item.url,
              # 'url' => parm,
              'links' => next_links(item)
            }
          end
          rsp['total'] = nxt_size
        end
        rtngs = index_links(curr, route, 'rating', curr.rule, r_range)
        p 'rtngs', rtngs
        rsp['ratings'] = rtngs #[r_range]
        rsp.delete('ratings') unless rsp['ratings'].present?
        if rsp['ratings'].present?
          rsp.delete('next')
          rsp.delete('total')
          rsp['total_ratings'] = rtngs.size
        end
        rsp['breadcrumbs'] = curr[:id] ? curr.breadcrumbs : rule.breadcrumbs
        JSON.dump(rsp)
      end

      def next_links(index)
        index.objects_dataset.order{Sequel.function(:random)}.limit(4).all.map do |lnk|
          {
            'name' => lnk.label,
            'url' => lnk.url,
            'photo' => lnk.photo
          }
        end
      end
    end
  end
end
