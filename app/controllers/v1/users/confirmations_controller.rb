# frozen_string_literal: true

class V1::Users::ConfirmationsController < Devise::ConfirmationsController
  clear_respond_to
  respond_to :json
  skip_before_action :require_2fa

  def show
    user = User.confirm_by_token(params[:confirmation_token])
    render json: { errors: user.errors }, status: :unprocessable_entity and return if user.errors.present?

    warden.set_user(user)
    render json: { token: request.env[Warden::JWTAuth::Hooks::PREPARED_TOKEN_ENV_KEY], otp_enabled: false }
  end
end
