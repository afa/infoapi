require 'tester'
require 'sequel'
require 'pp'
module SimpleApi
  class Rule
    ATTRS = %w(sphere call param lang design path path.level stars criteria content).map(&:to_sym) # add genres etc

    def self.from_param(param)
      SimpleApi::PARAM_MAP[param]
    end

    def initialize(hash)
      # p "hash init #{hash.inspect}"
      @data = {}
      @data.merge! hash.is_a?(Hash) ? hash : Hash[hash]
    end

    def rule_path
      [self.sphere, 'infotext', self.param, self.lang]
    end

    ATTRS.each do |meth|
      define_method(meth){ @data[meth.to_sym] }
      define_method(meth.to_s + '='){|val| @data[meth.to_sym] = val }
    end

    def mkdir_p(hash, path)
      #build hash-path.
      # rule_path.inject(hash) do |rslt, lvl|
      path.inject(hash) do |rslt, lvl|
        unless rslt.has_key?(lvl)
          rslt[lvl] = {}
        end
        rslt[lvl]
      end
    end

    def place_to(hash)
      mkdir_p(hash, rule_path[0..-2])
      place_at(hash)
    end

  end

  class DesignRule < Rule
    def rule_path
      super << design
    end

    def leaf_node
      {}
    end

    def place_at(hash)
      point = rule_path[0..-2].inject(hash){|rslt, item| rslt[item] }
      point[rule_path.last] = self
    end
  end

  class MainRule < DesignRule
  end

  class AboutRule < DesignRule
  end

  class AnnotationRule < Rule
    def leaf_node
      []
    end

    def place_at(hash)
      point = rule_path[0..-2].inject(hash){|rslt, item| rslt[item] }
      unless point.has_key?(rule_path.last)
        point[rule_path.last] = leaf_node
      end
      point[rule_path.last] << self
    end
  end

  class RatingAnnotationRule < AnnotationRule
  end

  class CatalogAnnotationRule < AnnotationRule
  end

  PARAM_MAP = {
    "catalog-annotation" => SimpleApi::CatalogAnnotationRule, #SimpleApi::CatalogAnnotationRule,
    "rating-annotation" => SimpleApi::RatingAnnotationRule,
    "about" => SimpleApi::AboutRule,
    "main" => SimpleApi::MainRule
  }

  class Rules
    class << self
      # def place_rule(rules, rule)
      #   rule.place_to(rules)
      # end

      def init(config)
        Sequel.postgres(config['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) }) do |db|
          @rules = {}
          db[:rules].order(:id).all.each{|item| Rule.from_param(item[:param]).new(item).place_to(@rules) }
          p 'rules', PP.pp(@rules)
        end
      end

      def prepare_params(params)
        OpenStruct.new(JSON.load(params))
      end

      def process(params, sphere, logger)
        located = @rules.fetch(sphere, {}).fetch('infotext', {}).fetch(params.param, {}).fetch(params.lang, {})
        found = %w(main about).include?(params.param) ? located[params.design] : located.detect do |rule|
          # r = OpenStruct.new JSON.load(rule)
          pairs = [[params.data ? params.data['path'] : params.path, rule.path]]
          pairs += [[params.data ? params.data['criteria'] : params.criteria, rule.criteria], [params.data ? params.data['stars'] : params.stars, rule.stars]] if params.param == 'rating-annotation'
          pairs.inject(true){|rslt, a| rslt && Tester::test(*a) }
        end
        logger.info "found #{found.inspect}"
        content = found.try(:content)
      end

    end
  end
end
