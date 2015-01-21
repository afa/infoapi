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

    end
  end
end
