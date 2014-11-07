source 'https://rubygems.org'

gem 'sentimeta'

gem "bundler", "~> 1.6"
gem "rake", "~> 10.0"
gem "sinatra"
gem "sinatra-contrib"
gem "thin"
gem "sequel"
gem "pg"
gem "json"

group :development do
  gem "capistrano"
  gem "capistrano-rvm"
  gem "capistrano-bundler"
  gem "capistrano-thin"
end
group *%i(development test) do
  gem "rspec"
  gem 'fakeweb', require: 'fakeweb/safe'
end
