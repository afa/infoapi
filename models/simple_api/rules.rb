require 'pp'
module SimpleApi
# require 'simple_api'
# require 'simple_api/rule'
  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules.each{|rule| rule.place_to(@rules) }
      end

      def load_rules
        Rule.order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] }
      end

      def connect_db(config)
      end

      def prepare_params(params)
        prm = OpenStruct.new(JSON.load(params))
        if prm.data.nil?
          prm.data = prm.filters
        end
        if prm.filters.nil?
          prm.filters = prm.data
        end
        if prm.filters["path"] && prm.filters["catalog"].nil?
          prm.filters["catalog"] = prm.filters["path"]
        end
        if prm.filters["catalog"] && prm.filters["path"].nil?
          prm.filters["path"] = prm.filters["catalog"]
        end
        p prm
        prm
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        logger.info "for sphere #{sphere} with params #{params.inspect} selected rule #{found.is_a?(Array) ? found.first.try(:id) : found.try(:id)} #{found.is_a?(Array) ? found.first.try(:name) : found.try(:name)}."
        content = found.kind_of?(Array) ? found.try(:first).try(:content) : found.try(:content)
      end

      def generate(sitemap = nil)
        SimpleApi::Rule.where(param: ['rating', 'rating-annotation').where('traversal_order is not null').order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] }.select{|rul| t = JSON.load(rul.traversal_order) rescue []; t.is_a?(::Array) && t.present? }.each do |rule|
          next if rule.traversal_order.blank?
          rule.generate(sitemap)
        end
        rework(sitemap)
      end

      def rework(sitemap)
        DB[:refs].where(sitemap_session_id: sitemap).order(:id).each do |ref|
          duble = DB[:refs].where{ Sequel.&( ( id < ref[:id]), { :url => ref[:url] }) }.order(:id).first
          param = JSON.load(ref[:json])
          rule = SimpleApi::Rule[param["rule"]]
          Sentimeta.env   = :staging # :production is default
          Sentimeta.lang  = rule.lang.to_sym
          Sentimeta.sphere = rule.sphere
          empty = (Sentimeta::Client.fetch :objects, {"is_empty" => true}.merge("criteria" => [param.delete('criteria')], "filters" => param.delete_if{|k, v| k == 'rule' }) rescue {})["is_empty"]
          DB[:refs].where(:id => ref[:id]).update(:is_empty => empty, :duplicate_id => duble.try(:[], :id))
        end
      end
    end
  end
end
