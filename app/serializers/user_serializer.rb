class UserSerializer < ApplicationSerializer
  attributes :id, :name

  attribute(:login) { |user| user.email }
  attribute(:emails) { |user| [ user.email ] }
end
