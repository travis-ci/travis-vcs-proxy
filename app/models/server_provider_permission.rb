# frozen_string_literal: true

class ServerProviderPermission < ApplicationRecord
  belongs_to :server_provider
  belongs_to :user

  has_one :setting, class_name: 'ServerProviderUserSetting', foreign_key: :server_provider_user_id, dependent: :delete

  enum permission: %i[owner member]
end
