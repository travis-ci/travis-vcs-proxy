# frozen_string_literal: true

class V1::UsersController < ApplicationController
  before_action :require_authentication, except: [:request_password_reset, :reset_password]

  def show
    render json: presented_entity(:user, current_user)
  end

  def update_email
    head :bad_request and return if params[:email].blank?

    current_user.email = params[:email]
    if current_user.save
      head :ok
      return
    end

    render json: { errors: current_user.errors }, status: :unprocessable_entity
  end

  def update_password
    head :bad_request and return if params[:password].blank? || params[:password_confirmation].blank?

    unless params[:password] == params[:password_confirmation]
      render json: { errors: [ 'Password does not match confirmation' ] }, status: :unprocessable_entity
      return
    end

    current_user.password = params[:password]
    current_user.password_confirmation = params[:password_confirmation]
    if current_user.save
      head :ok
      return
    end

    render json: { errors: current_user.errors }, status: :unprocessable_entity
  end

  def request_password_reset
    head :ok and return if params[:email].blank?
    head :ok and return unless user = User.find_by(email: params[:email])

    user.send_reset_password_instructions

    head :ok
  end

  def reset_password
    head :bad_request and return if params[:reset_password_token].blank? || params[:password].blank? || params[:password_confirmation].blank?

    user = User.reset_password_by_token(params.slice(:reset_password_token, :password, :password_confirmation))
    if user.errors.empty?
      head :ok
      return
    end

    render json: { errors: user.errors }, status: :unprocessable_entity
  end

  def emails
    render json: { emails: [ current_user.email ] }
  end

  def server_providers
    render json: {
      server_providers: current_user.server_providers.includes(:server_provider_permissions).map do |server_provider|
        {
          id: server_provider.id,
          name: server_provider.name,
          permission: current_user.server_provider_permission(server_provider.id).permission
        }
      end
    }
  end
end
