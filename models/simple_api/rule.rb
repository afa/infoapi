require 'simple_api'
require 'json'
require 'sequel'
require 'simple_api_router'
module SimpleApi
  class Rule < Sequel::Model
    plugin :after_initialize
    SERIALIZED = %w(stars criteria genres path).map(&:to_sym)
    attr :filter
    attr :filters

    def after_initialize
      super
      deserialize
    end

    def before_validation
      self.serialize
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
      return 'rating' if param == 'rating-annotation'
      return 'catalog' if param == 'catalog-annotation'
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
      self.filters = Filter.new(JSON.load(self.filter || "{}"))
      # (SERIALIZED).each{|attr| send("#{attr.to_s}=".to_sym, self.filters.try(:[], attr.to_s)) if self.filters.try(:[], attr.to_s) }
      self.filters.postprocess_init
      self.filters.traversal_order = self.traversal_order
      # self.filters.merge!(Hash[self.filters.map{|k, v| [k, v.nil? ? 'any' : v] }])
    end

    def serialize
      # (SERIALIZED).each{|attr| self.filters[attr.to_s] = send(attr) }
      self.traversal_order = self.filters.traversal_order.to_json
      self.filter = self.filters.to_json
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
          class_variable_get(:@@param_map).merge!(rcrd['sphere'] => {}) unless class_variable_get(:@@param_map)[rcrd['sphere']]
          class_variable_get(:@@param_map)[rcrd['sphere']][rcrd['param']] ||= rcrd['klass'].constantize
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

    def build_index(root)
      filters.build_index(root, self)
    end

    def write_ref(root_id, hash, index_id)
      refs = DB[:refs]
      route = SimpleApiRouter.new(lang, sphere)
      refs.insert(
        rule_id: pk,
        json: JSON.dump(hash),
        url: route.route_to('rating', hash),
        index_id: index_id
        # sitemap_session_id: sitemap ? sitemap.to_i : nil
      )
    end

    def generate(sitemap = nil, root)
      prod = build_index(root)
      # prod = filters.product(self)
      # prod = ((JSON.load(traversal_order) rescue []) || []).inject([self]) do |rslt, flt|
      #   klass = SimpleApi::RuleDefs.from_name(flt)
      #   rdef = klass.load_rule(self, flt)
      #   rslt.product(rdef.fetch_list).map(&:flatten)
      # end

      # data = prod.map do |arr|
      #   rs = {arr.first => arr[1..-1].select{|h| !h.values.all?{|v| v.nil? } }.inject({}){|r, h| r.merge(h) }}
      #   rs
      # end.select{|d| d.values.map(&:values).flatten.compact.present? }
      prod
    end
  end
end
