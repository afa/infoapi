module SimpleApi
  module RuleDefs
    require 'simple_api/rule_defs/extended_rule_item'
    require 'simple_api/rule_defs/default'
    require 'simple_api/rule_defs/numeric'
    require 'simple_api/rule_defs/string'
    require 'simple_api/rule_defs/catalog'
    require 'simple_api/rule_defs/criterion'

    DEFS = {
      'string' => SimpleApi::RuleDefs::String,
      'catalog' => SimpleApi::RuleDefs::Catalog,
      'path' => SimpleApi::RuleDefs::Catalog,
      'criterion' => SimpleApi::RuleDefs::Criterion,
      'default' => SimpleApi::RuleDefs::Default,
      'int' => SimpleApi::RuleDefs::Numeric
    }

    TYPES = {
    }

    def from_name(name)
      DEFS[TYPES[name].try(:[], 'kind') || 'default'] || SimpleApi::RuleDefs::Default
    end

    def load_definitions(stream)
      hash = JSON.load(stream)
      TYPES.delete_if{|i| true }.merge! hash
    end

    module_function :from_name, :load_definitions
  end
end
