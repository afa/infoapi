FactoryGirl.define do
  factory :vocabula, class: SimpleApi::Sitemap::Vocabula do
    label { Faker::Lorem.sentence(3, false, 0) }
    name { label.tr('.', '').split(' ').join('-') }
  end
end
