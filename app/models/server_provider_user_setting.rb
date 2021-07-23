# frozen_string_literal: true
require 'P4'

class ServerProviderUserSetting < ApplicationRecord
  belongs_to :permission, class_name: 'ServerProviderPermission', foreign_key: :server_provider_user_id
  validates_presence_of :username, :value, :server_provider_user_id

  def token=(token)
    self.value = encryptor.encrypt_and_sign(token)
  end

  def token
    encryptor.decrypt_and_verify(value)
  end

  private

  def encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(Settings.p4_token_encryption_key)
  end
end
