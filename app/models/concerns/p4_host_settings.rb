# frozen_string_literal: true

module P4HostSettings
  extend ActiveSupport::Concern

  included do
    has_settings(persistent: true) do |s|
      s.key :p4_host, defaults: { username: '', token: '' }
    end
  end
end