# frozen_string_literal: true

class V1::Users::TwoFactorAuthController < ApplicationController
  before_action :require_authentication
  skip_before_action :require_2fa, only: [:url, :enable]

  def url
    if current_user.otp_secret.blank?
      current_user.otp_secret = User.generate_otp_secret
      render json: { errors: current_user.errors } and return unless current_user.save
    end

    render json: { url: current_user.otp_provisioning_uri(current_user.email, issuer: 'Travis CI VCS Proxy') }
  end

  def enable
    current_user.otp_required_for_login = true
    render json: { errors: current_user.errors } and return unless current_user.save

    User.revoke_jwt(nil, current_user)
    warden.set_user(current_user)
    render json: { token: current_user_jwt_token, otp_enabled: true }
  end

  def codes
    codes = current_user.generate_otp_backup_codes!
    render json: { errors: current_user.errors } unless current_user.save

    render json: { codes: codes }
  end
end