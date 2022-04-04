# frozen_string_literal: true

module V1
  module Users
    class RegistrationsController < Devise::RegistrationsController
      clear_respond_to
      respond_to :json
      skip_before_action :require_2fa

      def create
        build_resource(sign_up_params)

        resource.save
        handle_invitation(params) if params['organization']
        if resource.persisted?
          expire_data_after_sign_in!
          head :ok
          return
        end

        render json: { errors: resource.errors }, status: :unprocessable_entity
      end

      def update
        head :not_found
      end

      def destroy
        unless resource.valid_password?(params[:password])
          render(json: { errors: ['Invalid credentials'] }, status: :unprocessable_entity) && return
        end

        if params[:feedback].present?
          permitted = params.require(:feedback).permit(:reason, :text)
          FeedbackMailer.with(email: resource.email, feedback: permitted).send_feedback.deliver_now
        end

        resource.mark_as_deleted
        sign_out
        head :ok
      end

      def cancel
        head :not_found
      end

      def handle_invitation(params)
        ::InviteUser.new(params['user']['email'], params['organization']['id'], params['organization']['role'], User.find(params['current_user']['id'])).call
      end
    end
  end
end
