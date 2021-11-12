# frozen_string_literal: true

module V1
  module Users
    class SessionsController < Devise::SessionsController
      clear_respond_to
      respond_to :json
      skip_before_action :require_2fa

      def create # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if !params.key?(:user) || params[:user][:email].blank? || params[:user][:password].blank?
          head(:bad_request) && return
        end
        user = User.find_by(email: params[:user][:email])
        head(:unauthorized) && return if user.blank?
        if user.valid_password?(params[:user][:password]) && user.otp_required_for_login? && params[:user][:otp_attempt].blank?
          render(json: { token: '', otp_enabled: true }) && return
        end

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
  end
end
