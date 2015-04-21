module SimpleApi
  module RuleDefs
    class CatalogRuleItem < ExtendedRuleItem
      attr_accessor :string, :array
      def initialize(flt, data)
        super
        parse_config
      end

      def fetch_list(rule)
        return self.array unless array.blank?
        return [self.string] unless self.string.blank?
        return [nil] if config == 'empty'
        p 'cnt fetch'
        list = SimpleApi::Sitemap::Vocabula.where(kind: 'catalog', lang: rule.lang, sphere: rule.sphere).all.map(&:name)
        list << nil if config == 'any'
        return list
        return [nil]
      end

      def parse_config
        if config.kind_of? ::Array
          self.array = config
          return
        end
        unless %w(any empty non-empty).include?(config)
          self.string = config.strip
          self.array = [string]
        end
      end

      def check(param)
        return true if super
        val = json_load(param.data[filter], param.data[filter]) # val is request
        return false if val.nil?
        return true if val.kind_of?(::String) && val == string
        false
      end

      def convolution(param)
        val = JSON.load(param) rescue param
        return nil if val.nil?
        return val.first if val.is_a?(::Array) && val.size == 1
        val.to_s
      end
    end

    module Catalog
      def load_rule(flt, cfg)
        SimpleApi::RuleDefs::CatalogRuleItem.new(flt, cfg)
      end

      module_function :load_rule
    end
  end
end
