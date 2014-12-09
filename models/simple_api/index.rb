module SimpleApi
  class Index
    class << self
      def roots(sphere)
        root = DB[:roots].reverse_order(:id).select(:id).where(sphere: sphere).first.tap{|x| p x }.try(:[], :id)
        JSON.dump(next: SimpleApi::Rule.where(sphere: sphere).where('traversal_order is not null').order(:position).all.select{|r| (JSON.load(r.traversal_order) rescue []).present? }.map{|r| {name: r.name, url:r.name} } )
      end

      def tree(sphere, rule_selector, rule_params)
        selector = rule_selector.strip.split(',')
        p selector
        p rule_params
        p params
        JSON.dump selector
        #parse
        rat = selector.shift
        return '[]' unless 'rating' == rat
        if selector.empty?
          return index_page
        end
        lang = "en"
        name = selector.shift
        return root_page(root) unless name.present?
        return root_page(root) unless rule = Rule.where(name: name).first
        fields = selector || []
        leaf_page()
      end

      def index_page(root)
        DB[:roots].where(root_id: root, parent_id: nil).all
      end

      def root_page
        '[]'
      end

      def leaf_page(root, rule, selector)
        '[]'
      end


    end
  end
end
