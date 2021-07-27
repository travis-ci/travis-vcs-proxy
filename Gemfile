source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.1'

gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
gem 'devise'
gem 'devise-jwt'
gem 'devise-two-factor'
gem 'ledermann-rails-settings'
gem 'pg'
gem 'redis'
gem 'puma', '~> 5.0'
gem 'rack-cors'
gem 'config'
gem 'jsonapi-serializer'
gem 'p4ruby'
gem 'sidekiq'
gem 'kaminari'

gem 'bootsnap', require: false

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot'
  gem 'rspec-rails'
  gem 'listen'
end

group :test do
  gem 'rspec'
end

group :development do
  gem 'rubocop', '~> 0.75.1', require: false
  gem 'rubocop-rspec'
end
