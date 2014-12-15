require 'spec_helper'
describe SimpleApi::Filter do
  describe 'on initialize' do
    context 'when kind unknown' do
      it "should build default rule" do
        expect(SimpleApi::Filter.new('abyr', 'valg')['abyr']).to be_is_a(SimpleApi::RuleDefs::DefaultRuleItem)
      end
    end
  end
  describe 'on like?' do
  end
  describe 'on build_index' do
  end
end
