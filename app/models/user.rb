# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  default_scope { where(active: true) }

  devise :two_factor_authenticatable,
         :registerable,
         :validatable,
         :confirmable,
         :jwt_authenticatable,
         :two_factor_backupable,
         :recoverable,
         jwt_revocation_strategy: self,
         otp_secret_encryption_key: Settings.otp_secret_encryption_key

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  validate :password_complexity

  has_many :organization_permissions
  has_many :organizations, through: :organization_permissions

  has_many :repository_permissions
  has_many :repositories, through: :repository_permissions

  def organization_permission(organization_id)
    organization_permissions.find_by(organization_id: organization_id)
  end

  def set_organization_permission(organization_id, permission)
    puts "permission: #{permission.inspect}"
    puts "orgid: #{organization_id.inspect}"
    perm = organization_permissions.find_or_initialize_by(organization_id: organization_id)
    perm.permission = permission
    puts "perm: #{perm.inspect}"
    perm.save
  end

  def remove_organization_permission(organization_id)
    perm = organization_permissions.find_by(organization_id: organization_id)
    perm.delete if perm
  end

  def repository_permission(repository_id)
    repository_permissions.find_by(repository_id: repository_id)
  end

  def mark_as_deleted
    update_columns(email: "deleted_email_#{Kernel.rand(1_000_000_000)}@example.com", name: nil, active: false)
  end

  private

  def password_complexity
    return if password.blank?

    return unless password =~ /\A[A-Za-z]+\z/

    errors.add(:password, 'should contain a non-alphabet character (number or special character)')
  end
end
