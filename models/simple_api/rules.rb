require 'pp'
require 'sentimeta'
Sentimeta.logger.level = Logger::WARN
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
        sp_list = (Sentimeta::Client.spheres rescue []).map{|s| s["name"] } + ["test", 'alien']
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

      def rule_list(param)
        SimpleApi::Rule.where(param).all.map(&:export_data)
      end

      def rule_item(id)
        SimpleApi::Rule[id].try(:export_data)
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
        data = json_load(content, {})
        subs = data.delete('substitutions')
        if subs.present? && subs[param.lang].present?
          data.merge!(subs)
        end
        JSON.dump(data)
      end

    end
  end
end
