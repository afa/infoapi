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
          resp = Net::HTTP.get_response(uri)
          resp.is_a?(Net::HTTPSuccess) ? true : resp.code
        rescue => e
          nil
        end.tap{|x| puts "chkresp #{x.inspect}" }
      end
    end
  end
end
