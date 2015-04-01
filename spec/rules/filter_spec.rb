require 'spec_helper'
describe SimpleApi::Filter do
  describe 'on initialize' do
    context 'when kind unknown' do
      it "should build default rule" do
        expect(SimpleApi::Filter.new('abyr' => 'valg')['abyr']).to be_is_a(SimpleApi::RuleDefs::DefaultRuleItem)
      end
    end
    context 'when has default' do
      it 'should build #default? rule' do
        expect(SimpleApi::Filter.new('abyr' => 'valg', 'default' => true).default?).to be_truthy
      end
    end
    context 'when kind string' do
      before(:example) do
        expect(SimpleApi::RuleDefs).to receive(:from_name).with('genres').and_return(SimpleApi::RuleDefs::String)
        # @defs = class_spy('SimpleApi::RuleDefs')
      end
      let(:g1_def){SimpleApi::RuleDefs::StringRuleItem.new('genres', 'test')}
      let(:g2_def){SimpleApi::RuleDefs::StringRuleItem.new('genres', ['test'])}
      it 'should make string' do
        expect(SimpleApi::RuleDefs::String).to receive(:load_rule).with('genres', 'test').and_return(g1_def)
        expect(SimpleApi::Filter.new('genres' => 'test')['genres']).to be_is_a(SimpleApi::RuleDefs::StringRuleItem)
      end
      it 'should make string2' do
        expect(SimpleApi::RuleDefs::String).to receive(:load_rule).with('genres', ['test']).and_return(g2_def)
        expect(SimpleApi::Filter.new('genres' => ['test'])['genres']).to be_is_a(SimpleApi::RuleDefs::StringRuleItem)
      end
    end
    context 'when kind int' do
      before(:example) do
        allow(SimpleApi::RuleDefs).to receive(:from_name).with('stars').and_return(SimpleApi::RuleDefs::Numeric)
        # @defs = class_spy('SimpleApi::RuleDefs')
      end
      let(:n1_def){SimpleApi::RuleDefs::NumericRuleItem.new('stars', 1)}
      let(:n2_def){SimpleApi::RuleDefs::NumericRuleItem.new('stars', '1')}
      let(:n3_def){SimpleApi::RuleDefs::NumericRuleItem.new('stars', '1-1')}
      let(:n4_def){SimpleApi::RuleDefs::NumericRuleItem.new('stars', '1-3')}
      it 'should make valid num from single num' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', 1).and_return(n1_def)
        expect(SimpleApi::Filter.new('stars' => 1)['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
      end
      it 'should make valid num from string with single num' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', '1').and_return(n2_def)
        expect(SimpleApi::Filter.new('stars' => '1')['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
      end
      it 'should make valid num from string with range 1' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', '1-1').at_least(1).times.and_return(n3_def)
        expect(SimpleApi::Filter.new('stars' => '1-1')['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
        expect(SimpleApi::Filter.new('stars' => '1-1')['stars'].range).to eql(1..1)
        expect(SimpleApi::Filter.new('stars' => '1-1')['stars'].config).to eql(1)
      end
      it 'should make valid num from string with range 1-3' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', '1-3').at_least(1).times.and_return(n4_def)
        expect(SimpleApi::Filter.new('stars' => '1-3')['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
        expect(SimpleApi::Filter.new('stars' => '1-3')['stars'].range).to eql(1..3)
      end
      it 'should make valid num from hash with range 1-3' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', {"from"=>1,"to"=>3}).at_least(1).times.and_return(n4_def)
        expect(SimpleApi::Filter.new('stars' => {"from"=>1,"to"=>3})['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
        expect(SimpleApi::Filter.new('stars' => {"from"=>1,"to"=>3})['stars'].range).to eql(1..3)
      end
      it 'should make valid num from hash with strings range 1-3' do
        expect(SimpleApi::RuleDefs::Numeric).to receive(:load_rule).with('stars', {"from"=>'1',"to"=>'3'}).at_least(1).times.and_return(n4_def)
        expect(SimpleApi::Filter.new('stars' => {"from"=>'1',"to"=>'3'})['stars']).to be_is_a(SimpleApi::RuleDefs::NumericRuleItem)
        expect(SimpleApi::Filter.new('stars' => {"from"=>'1',"to"=>'3'})['stars'].range).to eql(1..3)
      end
    end
  end
  describe 'on like?' do
  end
  describe 'on build_index' do
  end
end
