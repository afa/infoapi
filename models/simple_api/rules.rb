require 'pp'
require 'sentimeta'
module SimpleApi
  # require 'simple_api'
  # require 'simple_api/rule'
  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules.compact.each{|rule| rule.place_to(@rules) }
      end

      def load_rules
        Sentimeta.env = CONFIG["fapi_stage"] || :production
        # Sentimeta.lang = :en
        sp_list = (Sentimeta::Client.spheres rescue []).map{|s| s["name"] } << "test"
        # spheres = SimpleApi::Rule.take_spheres << "test"
        rls = Rule.order(:position).all.select do|rl|
          if sp_list.include?(rl.sphere)
            true
          else
            puts "drop rule #{rl.try(:id).to_s}"
            puts "rule id:#{rl.pk} name:#{rl.name.to_s} sphere:#{rl.sphere} param:#{rl.param}"
            false
          end
        end
        rls.map do |item|
          SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] rescue puts "error in rule #{item.id.to_s}" 
        end
      end

      def prepare_params(params)
        prm = OpenStruct.new(JSON.load(params))
        unless  prm.data.nil? && prm.filters.nil?
          if prm.data.nil?
            prm.data = prm.filters
          end
          if prm.filters.nil?
            prm.filters = prm.data
          end
          unless prm.filters["path"].nil? && prm.filters["catalog"].nil?
            if prm.filters["path"] && prm.filters["catalog"].nil?
              prm.filters["catalog"] = prm.filters["path"]
            end
            if prm.filters["catalog"] && prm.filters["path"].nil?
              prm.filters["path"] = prm.filters["catalog"]
            end
          end
        end
        prm.param = 'catalog' if prm.param == 'catalog-annotation'
        prm.param = 'rating' if prm.param == 'rating-annotation'
        prm
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        logger.info "for sphere #{sphere} with params #{params.inspect} selected rule #{found.is_a?(Array) ? found.first.try(:id) : found.try(:id)} #{found.is_a?(Array) ? found.first.try(:name) : found.try(:name)}."
        content = found.kind_of?(Array) ? found.try(:first).try(:content) : found.try(:content)
      end

      def make_index(sphere, param, name = nil, sitemap_id = nil)
        raise 'Need sphere to process' unless sphere
        name = sphere unless name
        root = DB[:roots].insert(sphere: sphere, sitemap_session_id: sitemap_id, name: name, param: param)
        SimpleApi::Rule.where(param: param, sphere: sphere).where('traversal_order is not null').order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] }.select{|rul| t = json_load(rul.traversal_order, []); t.is_a?(::Array) && t.present? }.each do |rule|
          rule.build_index(root)
        end
        # rework(index_id: DB[:indexes].where(root_id: root).map{|i| i[:id] })
        root_ids = DB[:roots].where(sphere: sphere, param: param).exclude(id: root).all.map{|r| r[:id] }
        index_ids = DB[:indexes].where(root_id: root_ids).all.map{|i| i[:id] }
        DB[:refs].where(index_id: index_ids).delete
        DB[:indexes].where(root_id: root_ids).delete
        DB[:roots].where(sphere: sphere, param: param).exclude(id: root).delete
      end

      def preload_criteria
        Sentimeta.env = CONFIG["fapi_stage"] || :production
        sp_list = ((Sentimeta::Client.spheres rescue []) || []).map{|s| s["name"] }
        DB[:criteria].delete
        (SimpleApi::Rule.all.map(&:sphere).uniq & sp_list).each do |sphere|
          Sentimeta.lang = :en
          Sentimeta.sphere = sphere
          DB[:criteria].multi_insert(((Sentimeta::Client.criteria(:subcriteria => true) rescue []) || []).map{|h| h.has_key?('subcriteria') ? h['subcriteria'] : [h] }.flatten.map{|h| {label: h["label"], name: h["name"], sphere: sphere} })
        end
      end

      # def generate(sitemap = nil)
      #   DB[:refs].where(sitemap_session_id: sitemap).delete
      #   SimpleApi::Rule.where(param: ['rating', 'rating-annotation']).where('traversal_order is not null').order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] }.each do |rule|
      #     next if rule.filters.traversal_order.blank?
      #     rule.generate(sitemap)
      #     # fix for null filters.
      #   end
      #   # rework(sitemap_session_id: sitemap)
      # end

      def rework_doubles(scope)
        # by rules
        doubles = DB[:refs].select{[min(id), url]}.group([:url]).having('count(*) > 1').where(rule_id: SimpleApi::Rule.where(param: 'group').all.map(&:pk)).all #.where(scope)
        doubles.each do |hsh|
          puts "rework double #{hsh[:min]}"
          rs = DB[:refs].order(:id).where(scope).where(url: hsh[:url]).all.select{|h| h[:id].to_i != hsh[:min].to_i }
          DB[:refs].where(:id => rs.map{|a| a[:id] }).update(:duplicate_id => hsh[:min])
        end
      end

      def rework_empty(scope)
        # by rule
        DB[:refs].where(is_empty: nil).where(rule_id: SimpleApi::Rule.where(param: 'group').all.map(&:pk)).order(:id).each do |ref| #where(scope).
          puts "rework empty #{ref[:id]}" if ref[:id].to_i % 100 == 0
          # duble = DB[:refs].where{ Sequel.&( ( id < ref[:id]), { url: ref[:url] }) }.where(scope).order(:id).first
          param = json_load(ref[:json], {})
          rule = SimpleApi::Rule[ref[:rule_id]]
          Sentimeta.env   = CONFIG["fapi_stage"] # :production is default
          Sentimeta.lang  = rule.lang.to_sym
          Sentimeta.sphere = rule.sphere
          path = param.delete("path").to_s.split(',')
          empty = (Sentimeta::Client.fetch :objects, {"is_empty" => true}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue {})["is_empty"]
          DB[:refs].where(:id => ref[:id]).update(:is_empty => empty)
        end
      end

      def rework_links(scope)
        # by rules
        Sentimeta.env   = CONFIG["fapi_stage"]
        SimpleApi::Rule.where(param: 'group').order(:id).all.each do |rule|
          Sentimeta.lang  = rule.lang.to_sym
          Sentimeta.sphere = rule.sphere
          router = SimpleApiRouter.new(rule.lang, rule.sphere)
          root = DB[:roots].where(sphere: rule.sphere).order(:id).last
          next unless root
          leafs = DB[:refs].select(:index_id).where(rule_id: rule.pk, duplicate_id: nil, is_empty: false).order(:rule_id, :index_id).all.map{|i| i[:index_id] }.uniq #where(scope).
          parents = []
          leafs.each do |index_id|
            index = DB[:indexes].where(id: index_id).first
            refs = DB[:refs].where(index_id: index_id).all
            # rule = SimpleApi::Rule[index[:rule_id]]
            param = json_load(index[:json])
            refs_param = json_load(refs.first[:json], {}).delete_if{|k, v| k == 'rule' || k == 'rule_id' }
            url = router.route_to('rating', refs_param.dup)
            label = tr_h1_params(json_load(rule.content)['h1'], refs_param)
            path = param.delete("path").to_s.split(',')
            data = (Sentimeta::Client.fetch :objects, {}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue {})
            next if data.blank?
            next if data['objects'].nil?
            puts "rework links #{rule.pk}:#{index[:id]}=#{data['objects'].size}.#{refs.size}"
            parents << index[:parent_id] if index[:parent_id]
            data['objects'].select{|o| o.has_key?('photos') && o['photos'].present? }.sample(8).each do |obj|
              DB[:object_data_items].insert( 
                                            url: url, #"/#{rule.lang}/#{rule.sphere}/objects/#{obj['full_id']}",
                                            photo: obj['photos'].try(:first).try(:[], 'url'),
                                              label: label, #obj['name'],
                                              rule_id: rule.pk,
                                              root_id: root[:id],
                                              index_id: index[:id]
                                           )
            end
          end
          until parents.blank?
            current = parents.uniq.dup
            parents.clear
            current.each do |index_id|
              index = DB[:indexes].where(id: index_id).first
              parents << index[:parent_id] if index[:parent_id]
              links = DB[:object_data_items].where(index_id: DB[:indexes].where(parent_id: index[:id]).all.map{|i| i[:id] }).all
              puts "propagate #{index[:id]}=#{links.size}"
              links.sample(8).each do |link|
                DB[:object_data_items].insert(url: link[:url], photo: link[:photo], label: link[:label], index_id: index[:id], rule_id: rule.pk, root_id: root[:id])
              end
            end
          end
          # p root
          links = DB[:object_data_items].where(rule_id: rule.pk, root_id: root[:id]).all.map{|h| h.delete_if{|k, v| %i(id index_id).include? k } }.uniq.sample(8).each do |link|
            DB[:object_data_items].insert(url: link[:url], photo: link[:photo], label: link[:label], index_id: nil, rule_id: rule.pk, root_id: root[:id])
          end
        end
      end

      def rework(scope)
        rework_doubles(scope)
        rework_empty(scope)
        rework_links(scope)
      end
    end
  end
end
