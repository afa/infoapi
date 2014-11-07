require 'tester'
require 'sequel'
require 'pp'
module SimpleApi
  class Rule
    ATTRS = %w(sphere call param lang design path path.level stars criteria content genres).map(&:to_sym)

    def self.from_param(sphere, param)
      SimpleApi::PARAM_MAP[sphere][param]
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

    def self.find_rule(sphere, params, rules)
      klass = from_param(sphere, params.param)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(params.param, {}).fetch(params.lang, {})
      p "located", located, klass
      klass.clarify(located, params)
    end
  end

  class DesignRule < Rule
    def self.clarify(located, params)
      located[params.design]
    end

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

  class HotelsRule < Rule
  end

  class MoviesRule < Rule
  end

  module AnnotationsRuleMethods
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

  class AnnotationHotelsRule < HotelsRule
    def self.clarify(located, params)
      located.select do |rule|
        Tester::test(params.data['path'], rule.path)
      end
    end

    include AnnotationsRuleMethods
  end

  class HotelsRatingAnnotationRule < AnnotationHotelsRule
    def self.clarify(located, params)
      super.select do |rule|
        Tester::test(params.data['criteria'], rule.criteria) && Tester::test(params.data['stars'], rule.stars)
      end
    end
  end

  class HotelsCatalogAnnotationRule < AnnotationHotelsRule
  end

  class AnnotationMoviesRule < MoviesRule
    def self.clarify(located, params)
      located.select do |rule|
        Tester::test(params.data['path'], rule.path) && Tester::test([params.data['genres']], rule.genres)
      end
    end

    include AnnotationsRuleMethods
  end

  class MoviesRatingAnnotationRule < AnnotationMoviesRule
  end

  class MoviesCatalogAnnotationRule < AnnotationMoviesRule
  end

    PARAM_MAP = {
      "hotels" => {
        "catalog-annotation" => SimpleApi::HotelsCatalogAnnotationRule,
        "rating-annotation" => SimpleApi::HotelsRatingAnnotationRule,
        "about" => SimpleApi::AboutRule,
        "main" => SimpleApi::MainRule
      },
      "movies" => {
        "catalog-annotation" => SimpleApi::MoviesCatalogAnnotationRule,
        "rating-annotation" => SimpleApi::MoviesRatingAnnotationRule,
        "about" => SimpleApi::AboutRule,
        "main" => SimpleApi::MainRule
      }
    }

  class Rules
    class << self
      def init(config)
        @rules = {}
        load_rules(config).each{|rule| rule.place_to(@rules) }
      end

      def load_rules(config)
        Sequel.postgres(config['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) }) do |db|
          db[:rules].order(:id).all.map{|item| Rule.from_param(item[:sphere], item[:param]).new(item) }
        end
      end

      def prepare_params(params)
        OpenStruct.new(JSON.load(params))
      end

      def process(params, sphere, logger)
        found = Rule.find_rule(sphere, params, @rules)
        logger.info "found #{found.inspect}"
        content = found.try(:first).try(:content)
      end
    end
  end
end
