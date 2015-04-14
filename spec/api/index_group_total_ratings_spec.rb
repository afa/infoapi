require 'spec_helper'
describe 'Index Group' do
  before do
    @root = build(:root, sphere: 'movies').save
    r = SimpleApi::Rule.insert(name: 'unknown-actors', filter: '{"criteria":"movies","actors":"ss"}', traversal_order: '["actors","criteria"]', sphere: 'movies', call: 'infotext', param: 'group', lang: 'en', content: '{"h1":"ttt","index":"vvv"}')
    @rule = SimpleApi::Rule[r]
    @index = build(:index, label: 'tt', url: '/en/movies/index/group,unknown-actors', root_id: @root.pk, rule_id: @rule.pk).save
    @refs = build_list(:ref, 51, index_id: @index.pk, root_id: @root.pk, rule_id: @rule.pk).tap{|x| x.each(&:save) }
    get URI.encode('/api/v1/movies/index/group,unknown-actors?p={"limit":10,"limit_ratings":50}')
  end
  it 'should return valid total_ratings' do
    expect(json_load(last_response.body)['total_ratings']).to be > 50
    
  end
end
