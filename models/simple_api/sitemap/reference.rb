module SimpleApi
  module Sitemap
    class Reference < Sequel::Model
      set_dataset :refs
      many_to_one :index, class: 'SimpleApi::Sitemap::Index'
      # many_to_one :super_index, class: 'SimpleApi::Sitemap::Index'
      many_to_one :rule, class: 'SimpleApi::Rule'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
    end
  end
end
