require 'json'

module Tester

  def Tester::test o, rule
    o     = JSON.parse(o) rescue o
    rule  = JSON.parse(rule) rescue rule

    result = case rule
    when 'empty'
      !o.present?
    when 'non-empty'
      o.present?
    when 'any'
      true
    else
      if o.kind_of?(Array)
        (rule & o).present?
      else
        o.to_s == rule
      end
    end
    puts "test #{ o } against #{ rule } : #{ result }"
    result
  end

end
