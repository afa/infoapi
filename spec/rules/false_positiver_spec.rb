require 'spec_helper'
require 'fakeweb'
describe SimpleApi::TestRule do
  before(:example) do
    @template = {
      sphere: "movies",
      call: "infotext",
      param: "rating-annotation",
      lang: "en",
      design: nil,
      content: "{\"title\":\"Best <%genre%> movies | TopRater.com\"}",
      position: 24,
      name: nil
    }
    FakeWeb.allow_net_connect = false
  end
  after(:example) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
  end
  context "for trw-620" do
    before(:example) do
      @trw620rule_right = SimpleApi::TestRule.create(@template.merge filter: "{\"criteria\":\"any\", \"path\":\"empty\",\"stars\":\"empty\",\"years\":\"empty\"}", name: 'yearrul', traversal_order: '[]')
      @trw620rule = SimpleApi::TestRule.create(@template.merge filter: "{\"criteria\":\"any\", \"path\":\"empty\",\"stars\":\"empty\",\"year\":\"empty\"}", name: 'yearrul', traversal_order: '[]')
      @dflt = SimpleApi::TestRule.create(@template.merge filter: '{"criteria":"any","path":"any","stars":"any","years":"any"}')
      # @located3 = [@trw620rule_right, @dflt]
    end
    let(:located) {[@trw620rule_right, @dflt]}
    let(:located_bad) {[@trw620rule, @dflt]}
    let(:located_bad2) {[@trw620rule, @dflt]}

      it "should not select 620 rule" do
        FakeWeb.register_uri(:get, 'http://5.9.0.5/api/v1/hotels/infotext?p=%7B%22lang%22:%22en%22,%22param%22:%22test-rule%22,%22data%22:%7B%22year%22:%221990%22%7D%7D', response: 'spec/fixtures/files/ask_trw-620.http')
        expect(SimpleApi::TestRule.clarify(located, OpenStruct.new(lang: "en", param: "test-rule", data: {"years"=>"2000"})).first).not_to eql(@trw620rule_right)
        expect(SimpleApi::TestRule.clarify(located, OpenStruct.new(lang: "en", param: "test-rule", data: {"years"=>"2000"})).first).to eql(@dflt)
        # expect(SimpleApi::TestRule.clarify(located_bad, OpenStruct.new(lang: "en", param: "test-rule", data: {"years"=>"2000"})).first).to eql(@dflt)
        expect(SimpleApi::TestRule.clarify(located_bad2, OpenStruct.new(lang: "en", param: "test-rule", data: {"year"=>"2000"})).first).to eql(@trw620rule)
    end
  end

end
