source 'https://rubygems.org'

gem 'sentimeta'

gem "bundler", "~> 1.6"
gem "rake", "~> 10.0"
gem "sinatra"
gem "thin"
gem "sequel"
gem "pg"

group :development do
  gem "capistrano"
  gem "capistrano-rvm"
  gem "capistrano-bundler"
  gem "capistrano-thin"
end
group *%i(development test) do
  gem "rspec"
  gem 'factory_girl'
  gem 'fakeweb', require: 'fakeweb/safe'
end
