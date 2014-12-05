module SimpleApi
  class Index
    class << self
      def roots
        []
      end

      def tree(sphere, rule_selector, rule_params)
        selector = rule_selector.strip.split(',')
        p selector
        p rule_params
        p params
        JSON.dump selector
        #parse
        rat = selector.shift
        return '[]' unless rating == rat
        if selector.empty?
        name = selector.shift
        fields = selector || []

      end



    end
  end
end
