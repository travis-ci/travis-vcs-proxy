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

  has_many :server_provider_permissions
  has_many :server_providers, through: :server_provider_permissions

  has_many :repository_permissions
  has_many :repositories, through: :repository_permissions

  def server_provider_permission(server_provider_id)
    server_provider_permissions.find_by(server_provider_id: server_provider_id)
  end

  def set_server_provider_permission(server_provider_id, permission)
    perm = server_provider_permissions.find_or_initialize_by(server_provider_id: server_provider_id)
    perm.permission = permission
    perm.save
  end

  def repository_permission(repository_id)
    repository_permissions.find_by(repository_id: repository_id)
  end

  def mark_as_deleted
    update_columns(email: "deleted_email_#{Kernel.rand(1_000_000_000)}", name: nil, active: false)
  end

  private

  def password_complexity
    return if password.blank?

    return unless password =~ /\A[A-Za-z]+\z/

    errors.add(:password, 'should contain a non-alphabet character (number or special character)')
  end
end
