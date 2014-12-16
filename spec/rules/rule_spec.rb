require 'spec_helper'
require 'simple_api/rule'
require 'fakeweb'

describe SimpleApi::Rule do
  before do
      @template = {
        sphere: "movies",
        call: "infotext",
        param: "rating-annotation",
        lang: "en",
        design: nil,
        # path: "any",
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

  describe "when testing for path trw-596" do
    before(:example) do
      @path_rule = SimpleApi::HotelsRatingAnnotationRule.new(@template.merge sphere: 'hotels', filter: "{\"stars\":\"5\"}", name: 'pathrul')
      @path2_rule = SimpleApi::HotelsRatingAnnotationRule.new(@template.merge sphere: 'hotels', filter: "{\"stars\":\"5\", \"path\":\"non-empty\"}", name: 'pathrul2')
      @located = [@path2_rule, @path_rule]
    end
    context "when testing for empty path" do
      it "should return pathrul2" do
        expect(SimpleApi::HotelsRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: 'en', param: 'rating', data: {"stars" => "5"}))).to be_an(Array)
        expect(SimpleApi::HotelsRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: 'en', param: 'rating', data: {"stars" => "5"})).first).to be_an(SimpleApi::HotelsRatingAnnotationRule)
        expect(SimpleApi::HotelsRatingAnnotationRule.clarify(@located, OpenStruct.new(lang: 'en', param: 'rating', data: {"stars" => "5"})).first.name).to eql('pathrul')
      end
    end
  end

  describe "when generating rating refs" do
    before(:example) do
      FakeWeb.allow_net_connect = false
      @root = 1
      @year_rule = SimpleApi::MoviesRatingAnnotationRule.create(@template.merge filter: "{\"years\":\"2000-2003\", \"genres\":[\"action\",\"fantasy\"]}", name: 'yearrul1', traversal_order: '["years", "genres"]')
      allow(@year_rule).to receive(:filters).and_return(SimpleApi::Filter.new({"years" => "2000-2003", "genres" => ["action", "fantasy"]}))

      # @year_rule.deserialize
      @genres_rule = SimpleApi::MoviesRatingAnnotationRule.create(@template.merge filters: "{\"genres\":\"non-empty\"}", name: 'genresrul', traversal_order: '["genres"]')
      @genres_rule.deserialize
      @any_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":null}", name: 'defstrul')
      @any_stars_rule.deserialize
      @two_stars_rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge filter: "{\"stars\":2}", name: 'strul') 
      @two_stars_rule.deserialize
      @located = [@two_stars_rule, @year_rule, @any_stars_rule]
    end
    after(:example) do
      FakeWeb.clean_registry
    end
    it "must generate product of metarules for list of genres & years from list" do
      rul = nil
      expect(@year_rule.filters).to receive(:build_index)
      expect(@year_rile.filters).to receive(:write_ref).exactly(8).times.and_call_original
      expect{rul = @year_rule.generate(nil, @root)}.to_not raise_error
      # expect(rul).to be_kind_of(Array)
      # expect(rul.size).to be_eql(8)
    end
    context "when any or non-empty" do
    it "must fetch genre list from api" do
      FakeWeb.register_uri(:any, 'http://5.9.0.5/api/v1/movies/attributes/genres?p=%7B%22limit_values%22:%20%2210000%22%7D', response: 'spec/fixtures/files/ask_genres.http')
      rul = @genres_rule.generate(nil, @root)
      expect(rul).to be_an(Array)
      expect(rul.size).to eql(27)
      # expect(rul.last.last["genres"]).to eql 'action'
    end
    it "must skip genre on error" do
      FakeWeb.register_uri(:any, 'http://5.9.0.5/api/v1/movies/attributes/genres?p=%7B%22limit_values%22:%20%2210000%22%7D', body: '{"error":"Internal server error"}')
      rul = @genres_rule.generate(nil, @root)
      expect(rul).to be_an(Array)
      expect(rul).to be_empty
      # expect(rul.last.last["genres"]).to eql 'action'
    end
    end
  end

end
