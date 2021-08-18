class UserSerializer < ApplicationSerializer
  attributes :id, :otp_required_for_login

  attribute(:name) { |user| user.name || user.email }
  attribute(:login) { |user| user.email }
  attribute(:emails) { |user| [ user.email ] }
  attribute(:servers) { |user| user.server_providers.map(&:id) }
  attribute(:uuid) { |user| user.id }
end
