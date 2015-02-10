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
        list = DB[:catalogs].select(:path).all.map{|i| i[:path] }
        list << nil if config == 'any'
        return list
        # return (array.empty? ? [string] : array) unless s[:meta]
        return [nil]
      end

      def self.prepare_list
        Sentimeta.env = CONFIG['fapi_stage']
        Sentimeta.lang = :en
        # Sentimeta.sphere = 'hotels'
        rslt = ['']
        crnt = rslt.dup
        4.times.each do
          # tst = crnt.partition{|item| Sentimeta::Client.catalog(path: item).blank? }
          # rslt += tst.first
          # rslt += tst.first.map{|item| Sentimeta::Client.catalog(path: item, limit: 10000).map{|i| i['name'] } }
          crnt = crnt.map do |item|
            cat = Sentimeta::Client.catalog(sphere: 'hotels', path: item, limit: 10000) rescue OpenStruct.new(body: [])
            cat.ok? && cat.body.present? ? cat.body.map{|i| [ item.blank? ? nil : item, i['name'] ].compact.join(',') } : nil
          end
          .compact
          .flatten
          rslt += crnt
        end
        DB[:catalogs].delete
        rslt.delete_if(&:blank?)
        rslt.each do |item|
          DB[:catalogs].insert(path: item)
        end
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
        # return true if val.kind_of?(::Array) && ((val & (array || []) == val) || ([string] == val))
        # return true if val.kind_of?(::String) && ((val == string) || ((array || []).include?(val)))
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
