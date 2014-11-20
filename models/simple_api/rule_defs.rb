module SimpleApi
  module RuleDefs
    require 'simple_api/rule_defs/extended_rule_item'
    require 'simple_api/rule_defs/default'
    require 'simple_api/rule_defs/numeric'
    require 'simple_api/rule_defs/string'

    DEFS = {
      'string' => SimpleApi::RuleDefs::String,
      'int' => SimpleApi::RuleDefs::Numeric
    }

    TYPES = {
    }

    def from_name(name)
      DEFS[TYPES[name]['kind']] || SimpleApi::RuleDefs::Default
    end

    def load_definitions(stream)
      hash = JSON.load(stream)
      TYPES.delete_if{|i| true }.merge! hash
    end

    def default?(rule)
      rule.filters.has_key?('default') && rule.filters['default']
    end

    module_function :from_name, :load_definitions, :default?
  end
end
