# frozen_string_literal: true

class RepositoryUserSetting < ApplicationRecord
  include EncryptedToken

  belongs_to :permission, class_name: 'RepositoryPermission', foreign_key: :repository_permission_id
  validates_presence_of :username, :value, :repository_permission_id

  def token=(token_value)
    self.value = encrypted_token(token_value)
  end

  def token
    decrypted_token(value)
  end
end
