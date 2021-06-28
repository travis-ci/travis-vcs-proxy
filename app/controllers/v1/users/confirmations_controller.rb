# frozen_string_literal: true

class V1::Users::ConfirmationsController < Devise::ConfirmationsController
  clear_respond_to
  respond_to :json

  def show
    resource = nil
    ActiveRecord::Base.transaction do
      resource = resource_class.confirm_by_token(params[:confirmation_token])

      if resource.errors.empty?
        resource.otp_required_for_login = true
        resource.otp_secret = resource_class.generate_otp_secret
        raise ActiveRecord::Rollback unless resource.save
      else
        raise ActiveRecord::Rollback
      end
    end

    head :ok and return if resource.errors.empty?

    render json: { errors: resource.errors }, status: :unprocessable_entity
  end
end
