# frozen_string_literal: true

class ServerProviderPermission < ApplicationRecord
  belongs_to :server_provider
  belongs_to :user

  has_one :setting, class_name: 'ServerProviderUserSetting', foreign_key: :server_provider_user_id, dependent: :delete

  OWNER = 1
  MEMBER = 2

  def owner?
    permission == OWNER
  end
end
