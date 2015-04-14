FactoryGirl.define do
  factory :index, class: SimpleApi::Sitemap::Index do
    label { Faker::Lorem.sentence }
  end
end
