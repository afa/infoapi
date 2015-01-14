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
        root_id = SimpleApi::Sitemap::Root.insert(sphere: sphere, sitemap_session_id: sitemap_id, name: name, param: param)
        SimpleApi::Rule.where(param: param, sphere: sphere).where('traversal_order is not null').order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.pk] }.select{|rul| t = json_load(rul.traversal_order, []); t.is_a?(::Array) && t.present? }.each do |rule|
          rule.build_index(SimpleApi::Sitemap::Root[root_id])
        end
        # rework(index_id: DB[:indexes].where(root_id: root).map{|i| i[:id] })
        root_ids = SimpleApi::Sitemap::Root.where(sphere: sphere, param: param).exclude(id: root_id).all.map(&:pk)
        index_ids = SimpleApi::Sitemap::Index.where(root_id: root_ids).all.map(&:pk)
        SimpleApi::Sitemap::Reference.where(index_id: index_ids).delete
        SimpleApi::Sitemap::Index.where(root_id: root_ids).delete
        SimpleApi::Sitemap::Root.where(sphere: sphere, param: param).exclude(id: root_id).delete
      end

      def rework(scope)
        SimpleApi::Sitemap.rework_doubles(scope)
        SimpleApi::Sitemap.rework_empty(scope)
        SimpleApi::Sitemap.rework_links(scope)
      end
    end
  end
end
