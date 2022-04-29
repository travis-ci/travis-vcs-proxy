# frozen_string_literal: true

class OrganizationInvitation < ApplicationRecord
  enum permission: %i[owner member]

  before_save :generate_token

  def generate_token
    return if token.present?

    self.token = SecureRandom.hex(40)
    self.created_at = Time.now
  end
end
