FactoryGirl.define do
  factory :rule, class: SimpleApi::Rule do
    name 'unknown-actors'
    lang 'en'
    sphere 'movies'
    call 'infotext'
    param 'group'
    content '{"h1":"ttt"}'
    filter '{"actors":"ss","criteria":"movies"}'
    traversal_order '["actors","movies"]'
    after(:build) {|inst| inst.deserialize; p 'ab', inst, inst.filter, inst.filters }
  end
end
