module SimpleApi
  module Sitemap
    class ObjectData < Sequel::Model
      set_dataset :object_data_items
      many_to_one :rule, class: 'SimpleApi::Rule'
      many_to_one :index, class: 'SimpleApi::Sitemap::Index'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'

      def check_photo
        begin
        uri = URI(photo)
        p uri
        Net::HTTP.get(uri).is_a?(Net::HTTPSuccess)
        rescue => e
          nil
        end
      end
    end
  end
end
