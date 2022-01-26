# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  PERMISSION_NAMES = {
    0 => 'Admin',
    1 => 'Member'
  }.freeze

  attributes :id, :otp_required_for_login

  attribute(:name) { |user| user.name || user.email }
  attribute(:login, &:email)
  attribute(:emails) { |user| [user.email] }
  attribute(:organizations) { |user| user.organizations.map(&:id) }
  attribute(:uuid, &:id)
  attribute(:permission) { |user| user.has_attribute?(:permission) ? PERMISSION_NAMES[user.permission] : '' }
  attribute(:org_permissions) { |user| OrganizationPermission.where(user_id: user.id).map { |perm| { id: perm.organization_id, permission: perm.permission } } }
end
