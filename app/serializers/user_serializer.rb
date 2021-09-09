# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  attributes :id, :otp_required_for_login

  attribute(:name) { |user| user.name || user.email }
  attribute(:login, &:email)
  attribute(:emails) { |user| [user.email] }
  attribute(:servers) { |user| user.server_providers.map(&:id) }
  attribute(:uuid, &:id)
end
