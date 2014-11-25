require 'spec_helper'
require 'simple_api/rule'

describe SimpleApi::Rule do
  before do
      @template = {
        sphere: "movies",
        call: "infotext",
        param: "rating-annotation",
        lang: "en",
        design: nil,
        path: "any",
        # path.level": null,
        content: "{\"title\":\"Best <%genre%> movies | TopRater.com\"}",
        # "filter": "{\"stars\":null,\"criteria\":null,\"genres\":\"[\\\"action\\\",\\\"adventure\\\",\\\"animation\\\",\\\"biography\\\",\\\"comedy\\\",\\\"crime\\\",\\\"documentary\\\",\\\"drama\\\",\\\"family\\\",\\\"fantasy\\\",\\\"film-noir\\\",\\\"history\\\",\\\"horror\\\",\\\"music\\\",\\\"musical\\\",\\\"mystery\\\",\\\"romance\\\",\\\"sci-fi\\\",\\\"sport\\\",\\\"thriller\\\",\\\"war\\\",\\\"western\\\"]\",\"years\":\"2000-2003\"}",
        position: 24,
        name: nil
      }
  end
  describe "when rulechecking request" do
    before do
      @year_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"years\":\"2000-2003\", \"genres\":[\"action\"]}", name: 'yearrul')
      @any_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":null}", name: 'defstrul')
      @two_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":2}", name: 'strul') 
      @located = [@two_stars_rule, @year_rule, @any_stars_rule]

    end
    describe 'when movies rule with any filter located' do
      it "should be ok" do
        expect(SimpleApi::MoviesRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: "en", param: "rating-annotation", data: {"years"=>"2000", "genres"=>"action"})).first).to be_eql(@year_rule)
        expect(SimpleApi::MoviesRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: "en", param: "rating-annotation", data: {"stars" => 2})).first).to be_eql(@two_stars_rule)
        expect(SimpleApi::MoviesRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: "en", param: "rating-annotation", data: {"stars" => "3"})).first).to be_eql(@any_stars_rule)

      end
    end
  end
  describe "when generating rating refs" do
    before(:example) do
      @year_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"years\":\"2000-2003\", \"genres\":[\"action\",\"fantasy\"]}", name: 'yearrul', traversal_order: '["years", "genres"]')
      @any_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":null}", name: 'defstrul')
      @two_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":2}", name: 'strul') 
      @located = [@two_stars_rule, @year_rule, @any_stars_rule]
    end
    it "must generate product of metarules" do
      expect{@year_rule.generate}.to_not raise_error
      expect(@year_rule.generate).to be_kind_of(Array)
      expect(@year_rule.generate.size).to be_eql(8)
      # expect(@year_rule.generate.size).to be_eql(8)
    end
  end

end
