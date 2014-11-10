require 'spec_helper'
require 'simple_api/rule'
describe :RulesDump do
  before do
    @rules = File.open(File.join(File.dirname(__FILE__), %w(.. .. db dump_rules.json)), 'r'){|f| JSON.parse(f.read.force_encoding('UTF-8')) }
  end

  it "should be valid json in content" do
    @rules.each do |rule|
      expect(rule).to be_has_key("content")
      expect {JSON.parse(rule["content"].force_encoding('UTF-8')) }.not_to raise_exception
    end
  end
end

