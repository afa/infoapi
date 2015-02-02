module SimpleApi
  module Sitemap
    class Root < Sequel::Model
      set_dataset :roots
      def breadcrumbs
        [
          {
            label: sphere,
            url: "/en/#{sphere}/index/group" #change when param added to self
          }
        ]
      end

      def clean_index
        SimpleApi::Sitemap::ObjectData.where(root_id: pk).delete
        ruls = SimpleApi::Rule.where(sphere: sphere).all.map(&:pk)
        SimpleApi::Sitemap::Reference.where(rule_id: ruls, sitemap_session_id: sitemap_session_id).delete
        SimpleApi::Sitemap::Index.where(root_id: pk).delete
        SimpleApi::Sitemap::Production.where(root_id: pk).update(root_id: nil)
        delete
      end
    end
  end
end
