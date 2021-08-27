# frozen_string_literal: true

Config.setup do |config|
  config.use_env = true
  config.env_prefix = 'SETTINGS'
  config.env_separator = '__'
end
