# frozen_string_literal: true

class P4ServerProvider < ServerProvider
  has_settings(persistent: true) do |s|
    s.key :p4_host
  end
end
