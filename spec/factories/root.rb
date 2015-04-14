FactoryGirl.define do
  factory :root, class: SimpleApi::Sitemap::Root do
    sphere { 'movies' }
  end
end
