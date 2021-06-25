# frozen_string_literal: true

class P4ServerProvider < ServerProvider
  has_settings :p4host, class_name: 'P4ServerSetting'
end
