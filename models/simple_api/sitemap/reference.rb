module SimpleApi
  module Sitemap
    class Reference < Sequel::Model
      set_dataset :refs
      many_to_one :index, class: 'SimpleApi::Sitemap::Index'
      many_to_one :super_index, class: 'SimpleApi::Sitemap::Index'
      many_to_one :rule, class: 'SimpleApi::Rule'
    end
  end
end
