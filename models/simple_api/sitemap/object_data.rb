module SimpleApi
  module Sitemap
    class ObjectData < Sequel::Model
      set_dataset :object_data_items
      many_to_one :rule, class: 'SimpleApi::Rule'
      many_to_one :index, class: 'SimpleApi::Sitemap::Index'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
    end
  end
end
