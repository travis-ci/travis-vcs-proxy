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

  validate :password_complexity

  has_many :server_provider_permissions
  has_many :server_providers, through: :server_provider_permissions

  has_many :repository_permissions
  has_many :repositories, through: :repository_permissions

  def server_provider_permission(server_provider_id)
    server_provider_permissions.find_by(server_provider_id: server_provider_id)
  end

  def set_server_provider_permission(server_provider_id, permission)
    perm = server_provider_permissions.first_or_initialize(server_provider_id: server_provider_id)
    perm.permission = permission
    perm.save
  end

  def mark_as_deleted
    update_columns(email: '', name: nil, active: false)
  end

  private

  def password_complexity
    return if password.blank?

    errors.add(:password, 'should contain a non-alphabet character (number or special character)') if password =~ /\A[A-Za-z]+\z/
  end
end
