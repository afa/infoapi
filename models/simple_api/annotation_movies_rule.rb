module SimpleApi
  class AnnotationMoviesRule < MoviesRule
    def self.clarify(located, params)
      located.select do |rule|
        Tester::test(params.data['path'], rule.path) && Tester::test([params.data['genres']], rule.genres)
      end.select do |rule|
        rule.extended.keys.inject(true) do |rslt, key|
          mod = SimpleApi::RuleDefs.from_name(key)
          r_data = mod.load_rule(rule)
          p = mod.parse_params(params, r_data)
          rslt && (rule.extended[key] & r_data.keys).inject(rslt) do |r, k|
            r && mod.like?(p[k], r_data[k])
          end
        end
      end

    end

    include AnnotationsRuleMethods
  end
end
