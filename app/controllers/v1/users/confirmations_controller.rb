# frozen_string_literal: true

class V1::Users::ConfirmationsController < Devise::ConfirmationsController
  clear_respond_to
  respond_to :json
  skip_before_action :require_2fa

  def show
    user = User.confirm_by_token(params[:confirmation_token])
    render json: { errors: user.errors }, status: :unprocessable_entity and return if user.errors.present?

    warden.set_user(user)
    render json: { token: current_user_jwt_token, otp_enabled: false }
  end

  def resend
    head :bad_request and return if params[:email].blank?

    user = User.find_by(email: params[:email])
    head :ok and return if user.blank? || user.confirmed?

    user.resend_confirmation_instructions

    head :ok
  end
end
