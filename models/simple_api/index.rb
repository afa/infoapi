module SimpleApi
  class Index
    class << self
      def roots(sphere)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first
        JSON.dump(
          next: SimpleApi::Rule.where(sphere: sphere, param: %w(rating rating-annotation)).where('traversal_order is not null').order(:position).all.select{|r| (JSON.load(r.traversal_order) rescue []).present? }.map{|r|
            {
              name: r.name,
              label: ((JSON.load(r.content) rescue '{}')['h1'] || r.name),
              links: {
                'name' => "Hotel Atlantida Mare",
                'url' => '/en/hotels/objects/426368-greece-crete-region-chania-hotel-atlantida-mare',
                'photo' => 'http://r-ec.bstatic.com/images/hotel/840x460/282/28265805.jpg'
              },
              url:"/en/#{sphere}/index/rating,#{r.name}"
            }
        }
        )
      end

      def tree(sphere, rule_selector, rule_params, params)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first[:id]
        selector = rule_selector.strip.split(',')
        rat = selector.shift
        # return roots(sphere) unless 'rating' == rat
        if selector.empty?
          return roots(sphere)
        end
        lang = "en"
        name = selector.shift
        return roots(sphere) unless name.present?
        return roots(sphere) unless rule = Rule.where(name: name, param: %w(rating rating-annotation)).first
        fields = selector || []
        leaf_page(root, rule, name, selector, params)
       end


      def index_links(bcr, curr, route)
        p bcr, curr
        sel = bcr # + [{item[:filter] => item[:value]}]
        url = route.route_to('rating', sel.inject({}){|r, h| r.merge(h) })
        links = DB[:refs].where(index_id: curr[:id], is_empty: false, duplicate_id: nil).all
        if links.present?
          links.map do |ref|
            lbl = JSON.load(SimpleApi::Rule[ref[:rule_id]][:content])['h1']
            {
              label: lbl,
              photo: '/en/hotels/objects/426368-greece-crete-region-chania-hotel-atlantida-mare',
              url: ref[:url]
            }
          end
        else
          '[]'
        end
      end

      def leaf_page(root, rule, name, selector, params)
        idx = DB[:indexes]
        parent = nil
        lded = JSON.load(params['p']) rescue params['p']
        lded ||= {}
        hash = {}
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
          return JSON.dump({'links' => index_links(bcr, parent, route)})
        end
        nxt = idx.where(root_id: root, rule_id: rule.pk, parent_id: curr[:id]).all
        rsp = {}
        if nxt.present?
          rsp['next'] = nxt.map do |item|
            sel = bcr + [{item[:filter] => item[:value]}]
            spath = sel.map{|i| i.keys.first }.join(',')
            parm = route.route_to("index/#{['rating', name, sel.blank? ? nil : sel.map{|i| i.keys.first }].compact.join(',')}", sel.inject({}){|r, i| r.merge(i) })
            {
              'label' => "#{item[:filter]}:#{item[:value]}",
              'name' => item[:filter],
              'url' => parm,
              'links' => next_links
            }
          end
        end
        rsp['links'] = index_links(bcr, curr, route)
        JSON.dump(rsp)
      end

      def next_links
        {
          'name' => "Hotel Atlantida Mare",
          'url' => '/en/hotels/objects/426368-greece-crete-region-chania-hotel-atlantida-mare',
          'photo' => 'http://r-ec.bstatic.com/images/hotel/840x460/282/28265805.jpg'
        }
# "full_id"=>"426368-greece-crete-region-chania-hotel-atlantida-mare",
#     "id"=>426368,
#       "is_mapped"=>true,
#         "lang"=>"en",
#           "name"=>"Hotel Atlantida Mare",
#             "overall_rating"=>0.92813945,
#               "photos"=>
#    [{"kind"=>"cover",
#           "type"=>"photo",
#                "url"=>"http://r-ec.bstatic.com/images/hotel/840x460/282/28265805.jpg"},

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
