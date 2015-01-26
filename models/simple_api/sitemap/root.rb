module SimpleApi
  module Sitemap
    class Root < Sequel::Model
      set_dataset :roots
      def breadcrumbs
        [
          {
            label: sphere,
            url: "/en/#{sphere}/index/#{param}"
          }
        ]
      end

      def clean_index
        SimpleApi::Sitemap::ObjectData.where(root_id: pk).delete
        idxs = SimpleApi::Sitemap::Index.where(root_id: pk).all.map(&:pk)
        SimpleApi::Sitemap::Reference.where(index_id: idxs).delete
        SimpleApi::Sitemap::Index.where(root_id: pk).delete
        delete
      end
    end
  end
end
