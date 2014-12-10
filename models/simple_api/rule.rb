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

    def self.map_param(param)
      return 'rating' if param == 'rating_annotation'
      return 'catalog' if param == 'catalog_annotation'
      param
    end

    def self.from_param(sphere, param)
      @@param_map[sphere].try(:[], map_param(param))
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
      [self.sphere, 'infotext', self.class.map_param(self.param), self.lang]
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

    def self.take_spheres
      (class_variable_get(:@@param_map) || {}).keys
    end

    def self.find_rule(sphere, params, rules)
      klass = from_param(sphere, params.param)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(map_param(params.param), {}).fetch(params.lang, {})
      klass.clarify(located, params)
    end

    def recurse_index(flst, root, parent, idx)
      return if flst.blank?
      wlst = flst.dup
      flt = wlst.shift
      klass = SimpleApi::RuleDefs.from_name(flt)
      rdef = klass.load_rule(self, flt)
      values = rdef.fetch_list
      values.each do |val|
        ix = idx.insert(root_id: root, parent_id: parent, filter: flt, value: val[flt], rule_id: self.pk)
        recurse_index(wlst, root, ix, idx)
      end
    end

    def build_index(root)
      idx = DB[:indexes]
      filter_list = JSON.load(traversal_order) rescue []
      recurse_index(filter_list, root, nil, idx)
    end

    def generate(sitemap = nil)
      refs = DB[:refs]
      prod = ((JSON.load(traversal_order) rescue []) || []).inject([self]) do |rslt, flt|
        klass = SimpleApi::RuleDefs.from_name(flt)
        rdef = klass.load_rule(self, flt)
        rslt.product(rdef.fetch_list).map(&:flatten)
      end

      data = prod.map do |arr|
        rs = {arr.first => arr[1..-1].select{|h| !h.values.all?{|v| v.nil? } }.inject({}){|r, h| r.merge(h) }}
        rs
      end.select{|d| d.values.map(&:values).flatten.compact.present? }
      route = SimpleApiRouter.new(lang, sphere)
      data.each do |movement|
        refs.insert(
          rule_id: id,
          json: JSON.dump({rule: movement.keys.first.id}.merge(movement.values.first)),
          url: route.route_to('rating', movement.values.first),
          sitemap_session_id: sitemap ? sitemap.to_i : nil
        )
      end
      data
    end
  end
end
