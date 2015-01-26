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
        SimpleApi::Sitemap::Index.where(root_id: pk).all.each do |index|
          index.objects.each{|o| o.delete }
          index.references.each{|r| r.delete }
        end
        SimpleApi::Sitemap::Index.where(root_id: pk).delete
        delete
      end
    end
  end
end
