# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.1'

gem 'bootsnap', require: false
gem 'config'
gem 'devise'
gem 'devise-jwt'
gem 'devise-two-factor'
gem 'doorkeeper'
gem 'jsonapi-serializer'
gem 'kaminari'
gem 'ledermann-rails-settings'
gem 'p4ruby'
gem 'pg'
gem 'puma', '~> 5.0'
gem 'rack-cors'
gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
gem 'redis'
gem 'sidekiq'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sentry-sidekiq'
gem 'validate_url'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot'
  gem 'listen'
  gem 'rspec-rails'
end

group :test do
  gem 'database_cleaner'
  gem 'rspec'
end

group :development do
  gem 'rubocop', '~> 0.75.1', require: false
  gem 'rubocop-rspec'
end
