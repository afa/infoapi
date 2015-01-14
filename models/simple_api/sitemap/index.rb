module SimpleApi
  module Sitemap
    class Index < Sequel::Model
      set_dataset :indexes
      one_to_many :objects, class: 'SimpleApi::Sitemap::ObjectData'
      many_to_one :rule, class: 'SimpleApi::Rule'
      many_to_one :parent, class: 'SimpleApi::Sitemap::Index'
      one_to_many :children, class: 'SimpleApi::Sitemap::Index', key: :parent_id
      one_to_many :references, class: 'SimpleApi::Sitemap::Reference'
    end
  end
end
