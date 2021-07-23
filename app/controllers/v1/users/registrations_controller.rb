# frozen_string_literal: true

class V1::Users::RegistrationsController < Devise::RegistrationsController
  clear_respond_to
  respond_to :json
  skip_before_action :require_2fa

  def create
    build_resource(sign_up_params)

    resource.save
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
    render json: { errors: [ 'Invalid credentials' ] }, status: :unprocessable_entity and return unless resource.valid_password?(params[:password])

    resource.mark_as_deleted
    sign_out
    head :ok
  end

  def cancel
    head :not_found
  end
end
