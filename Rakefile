# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new do |t|
    t.patterns = ['{app,spec}/**/*.rb', '{Rake,Gem}file', 'config.ru']
  end

  task default: %i[spec rubocop]
end
