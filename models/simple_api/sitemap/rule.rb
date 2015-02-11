module SimpleApi
  module Sitemap
    class Rule << Sequel::Model
      set_dataset :sitemap_rules
      many_to_one :original_rule, class: 'SimpleApi::Rule'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
      one_to_many :indexes, class: 'SimpleApi::Sitemap::Index'

      def self.from_original(rule)
      end
    end
  end
end
