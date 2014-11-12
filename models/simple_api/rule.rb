require 'simple_api'
module SimpleApi
  class Rule < Sequel::Model
    # plugin :single_table_inheritance, :type, model_map: SimpleApi::PARAM_MAP
    # EXTERNAL_ATTRS = %w(sphere call param lang content filter extended_types).map(&:to_sym)
    SERIALIZED = %w(stars criteria genres).map(&:to_sym)
    # ATTRS = %w(sphere call param lang design path stars criteria content genres extended extended_types).map(&:to_sym) #restore when need path.level
    attr_accessor *SERIALIZED
    attr :filter
    attr :extended
    attr :filters
    # attr :data

    # def data
    #   @data
    # end

    # def data=(hsh)
    #   @data = hsh
    # end

    def after_load
      super
      deserialize
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

    def extended
      @extended
    end

    def extended=(hsh)
      @extended = hsh
    end

    def self.from_param(sphere, param)
      SimpleApi::PARAM_MAP[sphere][param]
    end

    def initialize(hash)
      hash.delete_if{|k, v| k == :id }
      super
      p hash
      # self.data = {}
      # self.data.merge! hash.is_a?(Hash) ? hash : Hash[hash]
      # p self.data
      deserialize
    end

    def deserialize
      p SERIALIZED.map{|i| [i, send(i)]}
      p SERIALIZED.map{|i| [i, send(i)]}
      self.filters = JSON.load(self.filter || "{}")
      (SERIALIZED).each{|attr| send("#{attr.to_s}=".to_sym, self.filters.try(:[], attr)) if self.filters.try(:[], attr) }
      self.extended = JSON.load(extended_types)
      p 'ds et e f fs', extended_types, extended, filter, filters
    end

    def serialize
      p SERIALIZED.map{|i| [i, send(i)]}
      (SERIALIZED).each{|attr| p "sdata", attr, self.send(attr), self.filters; self.filters[attr] = send(attr) }
      p SERIALIZED.map{|i| [i, send(i)]}
      self.extended_types = JSON.dump(self.extended)
      self.filter = JSON.dump(self.filters)
      self
    end

    def rule_path
      [self.sphere, 'infotext', self.param, self.lang]
    end

    # ATTRS.each do |meth|
    #   data ||= {}
    #   p data, meth
    #   define_method(meth){ data[meth.to_sym] }
    #   define_method(meth.to_s + '='){|val| data[meth.to_sym] = val }
    # end

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
      klass.clarify(located, params)
    end
  end
end
