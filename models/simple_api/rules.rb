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
        OpenStruct.new(JSON.load(params))
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        logger.info "for sphere #{sphere} with params #{params.inspect} selected rule #{found.is_a?(Array) ? found.first.try(:id) : found.try(:id)} #{found.is_a?(Array) ? found.first.try(:name) : found.try(:name)}."
        content = found.kind_of?(Array) ? found.try(:first).try(:content) : found.try(:content)
      end

      def generate(sitemap = nil)
        SimpleApi::Rule.where('traversal_order is not null').order(:position).all.map{|item| SimpleApi::Rule.from_param(item.sphere, item.param)[item.id] }.each do |rule|
          next if rule.traversal_order.blank?
          rule.generate(sitemap)
        end
      end
    end
  end
end
