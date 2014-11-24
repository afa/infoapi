require 'simple_api'
module SimpleApi
  class Rule < Sequel::Model
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
      SimpleApi::PARAM_MAP[sphere].try(:[], param)
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

    def self.find_rule(sphere, params, rules)
      klass = from_param(sphere, params.param)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(params.param, {}).fetch(params.lang, {})
      klass.clarify(located, params)
    end

    def generate
      ((JSON.load(traversal_order) rescue []) || []).inject([self]) do |rslt, flt|
        rdef = SimpleApi::RuleDefs.from_name(flt).load_rule(self, flt)
        rslt.product(rdef.fetch_list).map(&:flatten)
      end
    end
  end
end
