# frozen_string_literal: true

require 'P4'

class ServerProviderUserSetting < ApplicationRecord
  include EncryptedToken

  belongs_to :permission, class_name: 'ServerProviderPermission', foreign_key: :server_provider_user_id
  validates_presence_of :username, :value, :server_provider_user_id

  def token=(token_value)
    self.value = encrypted_token(token_value)
  end

  def token
    decrypted_token(value)
  end
end
