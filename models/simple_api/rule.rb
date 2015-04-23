require 'simple_api'
require 'json'
require 'sequel'
require 'simple_api_router'
module SimpleApi
  class Rule < Sequel::Model
    plugin :after_initialize
    SERIALIZED = %w(stars criteria genres path).map(&:to_sym)
    # attr :filter
    attr :filters

    one_to_many :objects, class: 'SimpleApi::Sitemap::ObjectData'
    one_to_many :references, class: 'SimpleApi::Sitemap::Reference'
    one_to_many :indexes, class: 'SimpleApi::Sitemap::Index'

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

    # def filter
    #   values[:filter]
    # end

    # def filter=(hsh)
    #   values[:filter] = hsh
    # end

    def self.map_param(param)
      return 'rating' if param == 'rating-annotation'
      return 'catalog' if param == 'catalog-annotation'
      param
    end

    def self.from_param(sphere, param)
      @@param_map[map_param(param)]
      # @@param_map[sphere].try(:[], map_param(param))
    end

    def initialize(hash = {})
      hash.delete_if{|k, v| k == :id }
      super
    end

    def deserialize
      self.filters = Filter.new(json_load(self.filter, {}))
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
          class_variable_get(:@@param_map)[rcrd['param']] ||= rcrd['klass'].constantize
        end
      end
    end

    def self.take_spheres
      (class_variable_get(:@@param_map) || {}).keys
    end

    def self.find_rule(sphere, params, rules)
      klass = from_param(sphere, params.param)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(map_param(params.param), {}).fetch(params.lang, {})
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(map_param(params.param), {}).fetch('un', {}) unless located.present? && params.lang && params.lang == 'un'
      klass.clarify(located, params)
    end

    def build_index(root)
      filters.build_index(root, self)
    end

    def write_ref(root, hash, index_id)
      hsh = hash.dup
      hsh.merge!('catalog' => hsh.delete('path')) if hash.has_key?('path')
      route = SimpleApiRouter.new(lang, sphere)
      SimpleApi::Sitemap::Reference.insert(
        rule_id: pk,
        json: JSON.dump(hash),
        url: route.route_to('rating', hash),
        sitemap_session_id: root.sitemap_session_id,
        root_id: root.pk,
        index_id: index_id
      )
    end

    def breadcrumbs
      root = SimpleApi::Sitemap::Root.where(sphere: sphere).reverse_order(:id).first
      (root ? root.breadcrumbs : []) + [
        {
        label: json_load(content, {})['index'] || name,
        url: "/en/#{sphere}/index/#{param},#{name}"
      }]
    end

    def export_data
      deletable = %i(stars path path.level criteria genres extended_types order_traversal)
      to_hash.delete_if{|k, v| deletable.include? k }
    end
  end
end
