# frozen_string_literal: true

class V1::Users::SessionsController < Devise::SessionsController
  clear_respond_to
  respond_to :json
  skip_before_action :require_2fa

  def create
    resource = warden.authenticate!(auth_options)

    render json: { token: request.env[Warden::JWTAuth::Hooks::PREPARED_TOKEN_ENV_KEY], otp_enabled: resource.otp_required_for_login? }
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
