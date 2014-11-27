require 'simple_api'
require 'json'
require 'sequel'
require 'simple_api_router'
module SimpleApi
  class Rule < Sequel::Model
  # @@param_map = {
  #   "test-rule" => {
  #     "about" => SimpleApi::AboutRule,
  #     "catalog-annotation" => ::SimpleApi::HotelsCatalogAnnotationRule,
  #     "catalog" => ::SimpleApi::HotelsCatalogAnnotationRule,
  #     "rating-annotation" => ::SimpleApi::HotelsRatingAnnotationRule,
  #     "rating" => ::SimpleApi::HotelsRatingAnnotationRule,
  #     "main" => ::SimpleApi::MainRule
  #   },
  #   "hotels" => {
  #     "about" => SimpleApi::AboutRule,
  #     "catalog-annotation" => ::SimpleApi::HotelsCatalogAnnotationRule,
  #     "catalog" => ::SimpleApi::HotelsCatalogAnnotationRule,
  #     "rating-annotation" => ::SimpleApi::HotelsRatingAnnotationRule,
  #     "rating" => ::SimpleApi::HotelsRatingAnnotationRule,
  #     "main" => ::SimpleApi::MainRule
  #   },
  #   "movies" => {
  #     "catalog-annotation" => ::SimpleApi::MoviesCatalogAnnotationRule,
  #     "rating-annotation" => ::SimpleApi::MoviesRatingAnnotationRule,
  #     "catalog" => ::SimpleApi::MoviesCatalogAnnotationRule,
  #     "rating" => ::SimpleApi::MoviesRatingAnnotationRule,
  #     "about" => ::SimpleApi::AboutRule,
  #     "main" => ::SimpleApi::MainRule
  #   }
  # }
    plugin :after_initialize
    SERIALIZED = %w(stars criteria genres path).map(&:to_sym)
    # attr_accessor *SERIALIZED
    attr :filter
    # attr :extended
    attr :filters
    # attr :extended_types

    def after_initialize
      super
      deserialize
    end

    def before_validation
      self.serialize
    end

    def extract_series
    end

    def filters
      @filters
    end

    def filters=(hsh)
      @filters = hsh
    end

    def filter
      values[:filter]
    end

    def filter=(hsh)
      values[:filter] = hsh
    end

    def self.from_param(sphere, param)
      @@param_map[sphere].try(:[], param)
    end

    def initialize(hash)
      hash.delete_if{|k, v| k == :id }
      super
    end

    def deserialize
      self.filters = JSON.load(self.filter || "{}")
      (SERIALIZED).each{|attr| send("#{attr.to_s}=".to_sym, self.filters.try(:[], attr.to_s)) if self.filters.try(:[], attr.to_s) }
      self.filters.merge!(Hash[self.filters.map{|k, v| [k, v.nil? ? 'any' : v] }])
    end

    def serialize
      (SERIALIZED).each{|attr| self.filters[attr.to_s] = send(attr) }
      self.filter = JSON.dump(self.filters)
      self
    end

    def rule_path
      [self.sphere, 'infotext', self.param, self.lang]
    end

    def mkdir_p(hash, path_a)
      path_a.inject(hash) do |rslt, lvl|
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

    def self.init_spheres
      File.open(File.join(File.dirname(__FILE__), %w(.. .. db sphere_defs.json))) do |file|
        JSON.load(file).each do |rcrd|
          unless class_variable_defined? :@@param_map
            class_variable_set :@@param_map, {}
          end
            # rcrd.map{|r| r['sphere'] }.compact.uniq.each{|s| @@param_map[s] = {} }
              class_variable_get(:@@param_map).merge!(rcrd['sphere'] => {}) unless class_variable_get(:@@param_map)[rcrd['sphere']]
              class_variable_get(:@@param_map)[rcrd['sphere']][rcrd['param']] ||= rcrd['klass'].constantize
            # end

            # rcrd.compact.uniq.each{|a| @@param_map[a['sphere']][a['param']] = a['klass'].constantize }
        end
      end
    end

    def self.find_rule(sphere, params, rules)
      klass = from_param(sphere, params.param)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(params.param, {}).fetch(params.lang, {})
      klass.clarify(located, params)
    end

    def generate(sitemap = nil)
      refs = DB[:refs]
      prod = ((JSON.load(traversal_order) rescue []) || []).inject([self]) do |rslt, flt|
        klass = SimpleApi::RuleDefs.from_name(flt)
        if klass && !klass.is_a?(SimpleApi::RuleDefs::Default)
          rdef = klass.load_rule(self, flt)
          rslt.product(rdef.fetch_list).map(&:flatten)
        else
          rslt.product([])
        end
      end
      route = SimpleApiRouter.new(lang, sphere)
      p prod
      prod.each do |movement|
        refs.insert(
          rule_id: id,
          json: JSON.dump({rule: movement.first.id}.merge(movement[1..-1].inject({}){|rslt, k| rslt.merge(k) } )),
          url: route.route_to('rating', movement[1..-1].inject({}){|rslt, item| rslt.merge(item.keys.first => item.values.first) }),
          sitemap_session_id: sitemap ? sitemap.to_i : nil
        )
      end
      prod
    end
  end
end
