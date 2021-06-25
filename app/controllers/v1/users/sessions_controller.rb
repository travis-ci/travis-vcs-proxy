# frozen_string_literal: true

class V1::Users::SessionsController < Devise::SessionsController
  clear_respond_to
  respond_to :json

  # Overriding because we don't need to send any answer
  def create
    resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)

    head :ok
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
