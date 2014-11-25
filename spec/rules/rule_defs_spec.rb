require 'spec_helper'
require 'simple_api'
describe SimpleApi::RuleDefs do
  before do
    @template = {
      sphere: "movies",
      call: "infotext",
      param: "rating-annotation",
      lang: "en",
      content: "{\"title\":\"Best <%genre%> movies | TopRater.com\"}",
    }
  end
  context "when checking for" do
    context "string def" do
      before(:example) do
        @rule_arr = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump({"actors"=>["dike", "mike"]}), name: 'acts'))
        @rule_str = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump({"actors"=>"dike"}), name: 'acts'))
        @paramstr = OpenStruct.new(data: {'actors' => 'mike'}, lang: 'en', param: 'rating-annotation')
        @paramstr2 = OpenStruct.new(data: {'actors' => 'dike'}, lang: 'en', param: 'rating-annotation')
        @paramarr = OpenStruct.new(data: {'actors' => ['mike', 'dike']}, lang: 'en', param: 'rating-annotation')
        @paramarr2 = OpenStruct.new(data: {'actors' => ['mike', 'duck']}, lang: 'en', param: 'rating-annotation')
        allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("actors").and_return({"kind" => "string"})
      end
      it "should return rule for single str" do
        r = SimpleApi::RuleDefs::String.load_rule(@rule_arr, 'actors')
        expect(r.check(@paramstr)).to be_truthy
      end
      it "should return rule for array eq array in rule" do
        r = SimpleApi::RuleDefs::String.load_rule(@rule_arr, 'actors')
        expect(r.check(@paramarr)).to be_truthy
      end
      it "should nt return rule for array partally equal with array in rule" do
        r = SimpleApi::RuleDefs::String.load_rule(@rule_arr, 'actors')
        expect(r.check(@paramarr2)).to be_falsy
      end
      it "should return rule for single str param wit str rule" do
        r = SimpleApi::RuleDefs::String.load_rule(@rule_str, 'actors')
        expect(r.check(@paramstr2)).to be_truthy
      end
      it "should nt return rule for single str param iunlike wit str rule" do
        r = SimpleApi::RuleDefs::String.load_rule(@rule_str, 'actors')
        expect(r.check(@paramstr)).to be_falsy
      end
    end

    context "numeric def" do
      before(:example) do
        @rule_str = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump({"nms"=>"11"}), name: 'nms'))
        @rule_rng = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump({"nms"=>"11-13"}), name: 'rng'))
        @rule_num = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump({"nms"=>11}), name: 'nms'))
        @paramstr = OpenStruct.new(data: {'nms' => '11'}, lang: 'en', param: 'rating-annotation')
        @paramnum = OpenStruct.new(data: {'nms' => 11}, lang: 'en', param: 'rating-annotation')
        @paramrng = OpenStruct.new(data: {'nms' => '11-12'}, lang: 'en', param: 'rating-annotation')
        # @paramarr2 = OpenStruct.new(data: {'actors' => ['mike', 'duck']}, lang: 'en', param: 'rating-annotation')
        allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("nms").and_return({"kind" => "int", "min" => '10', "max" =>'15'})
      end
      it "should return strrule for str" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_str, 'nms')
        expect(r.check(@paramstr)).to be_truthy
      end
      it "should return strrule for num" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_str, 'nms')
        expect(r.check(@paramnum)).to be_truthy
      end
      it "should return strrule for rng" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_str, 'nms')
        expect(r.check(@paramrng)).to be_truthy
      end
      it "should return numrule for str" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_num, 'nms')
        expect(r.check(@paramstr)).to be_truthy
      end
      it "should return numrule for num" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_num, 'nms')
        expect(r.check(@paramnum)).to be_truthy
      end
      it "should return numrule for rng" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_num, 'nms')
        expect(r.check(@paramrng)).to be_truthy
      end
      it "should return rngrule for str" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_rng, 'nms')
        expect(r.check(@paramstr)).to be_truthy
      end
      it "should return rngrule for num" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_rng, 'nms')
        expect(r.check(@paramnum)).to be_truthy
      end
      it "should return rngrule for rng" do
        r = SimpleApi::RuleDefs::Numeric.load_rule(@rule_rng, 'nms')
        expect(r.check(@paramrng)).to be_truthy
      end
     end

    context "unknown def" do
    end
  end
  context "when preparing rules" do
    context "when taking ruletype" do
      before(:example) do
        allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("actors").and_return({"kind" => "string"})
        allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("nms").and_return({"kind" => "int"})
        allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("anthr").and_return(nil)
      end
      it 'should take string class for stringtype' do
        expect(SimpleApi::RuleDefs.from_name('actors')).to be_eql(SimpleApi::RuleDefs::String)
      end

      it 'should take number class for inttype' do
        expect(SimpleApi::RuleDefs.from_name('nms')).to be_eql(SimpleApi::RuleDefs::Numeric)
      end

      it 'should take default class for anyother' do
        expect(SimpleApi::RuleDefs.from_name('anthr')).to be_eql(SimpleApi::RuleDefs::Default)
      end
    end
  end
  context "when generating" do
    before(:example) do
      @rule = SimpleApi::MoviesRatingAnnotationRule.new(@template.merge(filter: JSON.dump('actors' => 'any')))
      allow(SimpleApi::RuleDefs::TYPES).to receive(:[]).with("actors").and_return({"kind" => "string", 'fetch_list' => 'attributes'})
    end
    context "when any rule" do
      before do
        @gen = SimpleApi::RuleDefs.from_name('actors')
      end
      it 'should load list' do
        r = @gen.load_rule(@rule, 'actors')
        p r.fetch_list
      end
    end
  end
end
