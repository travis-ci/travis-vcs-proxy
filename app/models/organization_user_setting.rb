# frozen_string_literal: true

class OrganizationUserSetting < ApplicationRecord
  include EncryptedToken

  belongs_to :permission, class_name: 'OrganizationPermission', foreign_key: :organization_user_id
  validates_presence_of :username, :value, :organization_user_id

  def token=(token_value)
    self.value = encrypted_token(token_value)
  end

  def token
    decrypted_token(value)
  end
end
