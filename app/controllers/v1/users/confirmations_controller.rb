# frozen_string_literal: true

module V1
  module Users
    class ConfirmationsController < Devise::ConfirmationsController
      clear_respond_to
      respond_to :json
      skip_before_action :require_2fa

      def show
        user = User.confirm_by_token(params[:confirmation_token])
        if user.errors.present?
          redirect_uri = URI.join(Settings.web_url, 'unconfirmed')
          redirect_uri.query = 'error=expired'
          redirect_to(redirect_uri.to_s) && return
        end

        redirect_to URI.join(Settings.web_url, 'confirmed').to_s
      end

      def resend
        head(:bad_request) && return if params[:email].blank?

        user = User.find_by(email: params[:email])
        head(:ok) && return if user.blank? || user.confirmed?

        user.resend_confirmation_instructions

        head :ok
      end
    end
  end
end
