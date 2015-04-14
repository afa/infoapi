FactoryGirl.define do
  factory :ref, class: SimpleApi::Sitemap::Reference do
    label { Faker::Lorem.sentence }
  end
end
