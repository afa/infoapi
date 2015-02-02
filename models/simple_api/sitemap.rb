require 'simple_api/sitemap/object_data'
require 'simple_api/sitemap/index'
require 'simple_api/sitemap/root'
require 'simple_api/sitemap/reference'
require 'simple_api/sitemap/production'
require 'simple_api/sitemap/sitemap_session'
require 'workers'
module SimpleApi
  module Sitemap
    # def rework_doubles(scope)
    #   # by rules
    #   doubles = SimpleApi::Sitemap::Reference.select{[min(id).as(:min_id), url]}.group([:url]).having('count(*) > 1').where(rule_id: SimpleApi::Rule.where(param: 'group').all.map(&:pk)).all #.where(scope)
    #   doubles.each do |dble|
    #     puts "rework double #{dble[:min_id]}"
    #     rs = SimpleApi::Sitemap::Reference.order(:id).where(scope).where(url: dble.url).all.select{|h| h.id != dble[:min_id].to_i }
    #     SimpleApi::Sitemap::Reference.where(:id => rs.map(&:pk)).update(:duplicate_id => dble[:min_id])
    #   end
    # end

    # def rework_empty(scope)
    #   # by rule
    #   SimpleApi::Rule.where(param: 'group').all.each do |rule|
    #     rule.references_dataset.where(is_empty: nil).order(:id).all.each do |obj|
    #       # DB[:refs].where(is_empty: nil).where(rule_id: SimpleApi::Rule.where(param: 'group').all.map(&:pk)).order(:id).each do |ref| #where(scope).
    #       puts "rework empty #{rule.pk}:#{obj.pk}" if obj.pk % 100 == 0
    #       param = json_load(obj.json, {})
    #       Sentimeta.env   = CONFIG["fapi_stage"] # :production is default
    #       Sentimeta.lang  = rule.lang.to_sym
    #       Sentimeta.sphere = rule.sphere
    #         path = param.delete('catalog').to_s.split(',') if param.has_key?('catalog')
    #         path = param.delete("path").to_s.split(',') if param.has_key?('path')
    #       # path = param.delete("path").to_s.split(',')
    #       empty = (Sentimeta::Client.fetch :objects, {"is_empty" => 4}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue {})["is_empty"]
    #       obj.update(:is_empty => empty)
    #     end
    #   end
    # end

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

    #   def rework_links(scope)
    #     # by rules
    #     Sentimeta.env   = CONFIG["fapi_stage"]
    #     SimpleApi::Rule.where(param: 'group').order(:id).all.each do |rule|
    #       Sentimeta.lang  = rule.lang.to_sym
    #       Sentimeta.sphere = rule.sphere
    #       router = SimpleApiRouter.new(rule.lang, rule.sphere)
    #       root = SimpleApi::Sitemap::Root.where(sphere: rule.sphere).order(:id).last
    #       next unless root
    #       leafs = rule.references_dataset.where(is_empty: false).order(:rule_id, :index_id).all.map{|i| i.index }.uniq #where(scope).
    #       # leafs = rule.references_dataset.where(duplicate_id: nil, is_empty: false).order(:rule_id, :index_id).all.map{|i| i.index }.uniq #where(scope).
    #       parents = []
    #       leafs.each do |index|
    #         refs = index.references
    #         param = json_load(index.json)
    #         refs_param = json_load(refs.first.json, {}).delete_if{|k, v| k == 'rule' || k == 'rule_id' }
    #         url = router.route_to('rating', refs_param.dup)
    #         label = tr_h1_params(json_load(rule.content)['h1'], refs_param)
    #         path = param.delete('catalog').to_s.split(',') if param.has_key?('catalog')
    #         path = param.delete("path").to_s.split(',') if param.has_key?('path')
    #         data = (Sentimeta::Client.fetch :objects, {'fields' => {'limit_objects' => '100'}}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue {})
    #         next if data.blank?
    #         next if data['objects'].nil?
    #         puts "rework links #{rule.pk}:#{index.pk}=#{data['objects'].size}.#{refs.size}"
    #         parents << index.parent if index.parent
    #         data['objects'].select{|o| o.has_key?('photos') && o['photos'].present? && o['photos'].select{|p| p['type'] != 'trailer'}.present? }.sample(8).each do |obj|
    #           index.objects_dataset.insert( 
    #                                url: url, #"/#{rule.lang}/#{rule.sphere}/objects/#{obj['full_id']}",
    #                                photo: obj['photos'].select{|p| p['type'] != 'trailer'}.try(:first).try(:[], 'url'),
    #                                label: label, #obj['name'],
    #                                rule_id: rule.pk,
    #                                root_id: root.pk,
    #                                index_id: index.pk
    #                               )
    #         end
    #       end
    #       until parents.blank?
    #         current = parents.uniq.dup
    #         parents.clear
    #         current.each do |index|
    #           parents << index.parent if index.parent
    #           links = index.children.map{|i| i.objects }.flatten
    #           # DB[:object_data_items].where(index_id: DB[:indexes].where(parent_id: index[:id]).all.map{|i| i[:id] }).all
    #           puts "propagate #{index.pk}=#{links.size}"
    #           links.sample(8).each do |link|
    #             index.objects_dataset.insert(index_id: index.pk, url: link.url, photo: link.photo, label: link.label, rule_id: rule.pk, root_id: root.pk)
    #           end
    #         end
    #       end
    #       links = rule.objects_dataset.where(root_id: root.pk).all.uniq.sample(8).each do |link|
    #         rule.objects_dataset.insert(url: link.url, rule_id: rule.pk, photo: link.photo, label: link.label, index_id: nil, root_id: root.pk)
    #       end
    #     end
    #   end

    #   def rework_forwardable(sphere)
    #     root_ids = SimpleApi::Sitemap::Root.where(sphere: sphere).all.map(&:pk)
    #     puts "todo: #{SimpleApi::Sitemap::Index.forwardables(root_id: root_ids).size}"
    #     # loop do
    #     #   break unless fwd = SimpleApi::Sitemap::Index.forwardables(root_id: root_ids).first
    #     #   parent = fwd.parent
    #     #   flt = json_load(parent.filter, parent.filter)
    #     #   val = json_load(parent.value, parent.value)
    #     #   flt = [flt] unless flt.is_a?(::Array)
    #     #   val = [val] unless val.is_a?(::Array)
    #     #   fwd.update(parent_id: parent.parent_id, filter: JSON.dump(flt + [json_load(fwd.filter, fwd.filter)].flatten), value: JSON.dump(val + [json_load(fwd.value,fwd.value)]))
    #     #   parent.delete
    #     # end
    #     loop do
    #       break if SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root_ids).empty?
    #       SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root_ids).each do |fwd_idx|
    #         fwd = SimpleApi::Sitemap::Index[fwd_idx[:id]]
    #         next unless fwd
    #         parent = fwd.parent
    #         flt = json_load(parent.filter, parent.filter)
    #         val = json_load(parent.value, parent.value)
    #         flt = [flt] unless flt.is_a?(::Array)
    #         val = [val] unless val.is_a?(::Array)
    #         fwd.update(parent_id: parent.parent_id, filter: JSON.dump(flt + [json_load(fwd.filter, fwd.filter)].flatten), value: JSON.dump(val + [json_load(fwd.value,fwd.value)]))
    #         parent.delete
    #       end
    #     end
    #     index_ids = SimpleApi::Sitemap::Index.where(root_id: root_ids).all.map(&:pk)
    #     refs = SimpleApi::Sitemap::Reference.where(index_id: index_ids, super_index_id: nil).order(:id).all
    #     puts "todo: #{refs.size} refs"
    #     refs.each do |ref|
    #       ref.update(super_index_id: ref.index.parent_id)
    #       print '.' if ref.pk % 100 == 0
    #     end
    #     puts '', 'done'
    #   end

    # module_function :rework_doubles, :rework_empty, :preload_criteria, :rework_links, :rework_forwardable
    module_function :preload_criteria
  end
end
