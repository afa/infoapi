module SimpleApi
  class AnnotationHotelsRule < HotelsRule
    def self.clarify(located, params)
      located.select do |rule|
        Tester::test(params.data['path'], rule.path)
      end.select do |rule|
        rule.filter['ext'].inject(true) do |ext|
          mod = SimpleApi::RuleDefs.from_name(ext)
          r_data = mod.load_rule(rule)
          p = mod.parse_params(params)
          mod.like?(p, r_data)
        end
      end
    end

    include AnnotationsRuleMethods
  end
end
