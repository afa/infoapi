module SimpleApi
  module Sitemap
    class SitemapSession < Sequel::Model
      set_dataset :sitemap_sessions

      one_to_many :roots, class: 'SimpleApi::Sitemap::Root'
    end
  end
end
