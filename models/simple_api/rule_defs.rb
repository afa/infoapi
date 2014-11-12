module SimpleApi
module RuleDefs
  require 'simple_api/rule_defs/year'
  require 'simple_api/rule_defs/numeric'

  DEFS = {
    'year' => SimpleApi::RuleDefs::Year,
    'numeric' => SimpleApi::RuleDefs::Numeric
  }

  def from_name(name)
    DEFS[name]
  end

  module_function :from_name
end
end
