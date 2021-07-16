# frozen_string_literal: true

class V1::Users::SessionsController < Devise::SessionsController
  clear_respond_to
  respond_to :json
  skip_before_action :require_2fa

  def create
    head :bad_request and return if !params.has_key?(:user) || params[:user][:email].blank? || params[:user][:password].blank?
    user = User.find_by(email: params[:user][:email])
    head :unauthorized and return if user.blank?
    render json: { token: '', otp_enabled: true } and return if user.valid_password?(params[:user][:password]) && user.otp_required_for_login?

    user = warden.authenticate!(auth_options)

    render json: { token: current_user_jwt_token, otp_enabled: user.otp_required_for_login? }
  end

  private

  # Overriding because we don't need to send any answer
  def respond_to_on_destroy
    head :ok
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
