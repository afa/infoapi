module SimpleApi
module RuleDefs
  require 'simple_api/rule_defs/default'
  require 'simple_api/rule_defs/numeric'

  DEFS = {
    # 'year' => SimpleApi::RuleDefs::Year,
    'int' => SimpleApi::RuleDefs::Numeric
  }

  def from_name(name)
    DEFS[name] || SimpleApi::RuleDefs::Default
  end

  module_function :from_name
end
end
