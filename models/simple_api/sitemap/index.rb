module SimpleApi
  module Sitemap
    class Index < Sequel::Model
      set_dataset :indexes
      one_to_many :objects, class: 'SimpleApi::Sitemap::ObjectData'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
      many_to_one :rule, class: 'SimpleApi::Rule'
      many_to_one :parent, class: 'SimpleApi::Sitemap::Index'
      one_to_many :children, class: 'SimpleApi::Sitemap::Index', key: :parent_id
      one_to_many :references, class: 'SimpleApi::Sitemap::Reference'

      def self.forwardable_indexes(scope)
        SimpleApi::Sitemap::Index.select{min(:id).as(:id)}.where(scope).group(:parent_id).having{count(:id) < 2}.all
      end

      def self.forwardables(scope)
        forwardable_indexes(scope).map{|s| SimpleApi::Sitemap::Index[s.id] }
      end

      def preprocess_filter # return array of hashes
      end

      def path_to_root
        bcr = [self]
        curr = self
        while curr = curr.parent
          bcr << curr
        end
        bcr.reverse
      end

      def label
        p filter, value
        [json_load(filter, filter)].flatten.zip([json_load(value, value)].flatten).map{|a| a.join(':') }.join(',')
      end

      def breadcrumbs
        rule.breadcrumbs + path_to_root.map do |idx|
        {
          'label' => idx.label,
          'url' => idx.url
        }
        end

      end

      def url
        route = SimpleApiRouter.new(:en, rule.sphere)
        route.route_to("index/#{[rule.param, rule.name, path_to_root.blank? ? nil : path_to_root.map{|i| json_load(i.filter, [i.filter]).join(',') }].compact.join(',')}", path_to_root.map{|a| json_load(a.filter, [a.filter]).zip(json_load(a.value, [a.value])) }.map{|a| Hash[a] }.inject({}){|r, i| r.merge(i) })
      end
    end
  end
end
