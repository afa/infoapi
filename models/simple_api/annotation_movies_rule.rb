module SimpleApi
  class AnnotationMoviesRule < MoviesRule
    def self.clarify(located, params)
      located.select do |rule|
        Tester::test(params.data['path'], rule.path) && Tester::test([params.data['genres']], rule.genres)
      end
    end

    include AnnotationsRuleMethods
  end
end
