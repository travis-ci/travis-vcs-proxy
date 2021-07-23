# frozen_string_literal: true

class V1::ServerProvidersController < ApplicationController
  PROVIDER_KLASS = {
    'perforce' => P4ServerProvider
  }.freeze

  before_action :require_authentication
  before_action :set_server_provider, only: [:show, :update, :authenticate, :forget, :repositories, :sync]

  def create
    head :bad_request and return if params[:server_provider].blank? || !PROVIDER_KLASS.has_key?(params[:server_provider][:type])

    success = true
    klass = PROVIDER_KLASS[params[:server_provider][:type]]
    errors = []
    provider = nil
    ActiveRecord::Base.transaction do
      unless provider = klass.find_by(name: params[:server_provider][:name])
        provider = klass.new(server_provider_params)
        unless provider.save
          success = false
          errors = provider.errors
          raise ActiveRecord::Rollback
        end
      end

      unless current_user.set_server_provider_permission(provider.id, ServerProviderPermission::OWNER)
        success = false
        errors << 'Cannot set permission for user'
        raise ActiveRecord::Rollback
      end
    end

    data = presented_entity(:server_provider, provider)
    data[:type] = PROVIDER_KLASS.invert[data[:type].constantize]

    render json: data and return if success

    render json: { errors: provider.errors }, status: :unprocessable_entity
  end

  def show
    data = presented_entity(:server_provider, @server_provider)
    data[:type] = PROVIDER_KLASS.invert[data[:type].constantize]

    render json: data
  end

  def update
    permission = current_user.server_provider_permission(@server_provider.id)
    head :forbidden and return if permission.blank? || !permission.owner?

    update_params = server_provider_params.dup
    if params.has_key?(:server_provider) && params[:server_provider][:token].present?
      update_params[:listener_token] = params[:server_provider][:token]
    end

    if @server_provider.update(update_params)
      head :ok
      return
    end

    render json: { errors: @server_provider.errors }, status: :unprocessable_entity
  end

  def authenticate
    head :bad_request and return if params[:token].blank? || params[:username].blank?

    success = true
    ActiveRecord::Base.transaction do
      permission = current_user.server_provider_permissions.first_or_initialize(server_provider_id: @server_provider.id)
      unless permission.persisted?
        permission.permission = ServerProviderPermission::MEMBER
        unless permission.save
          success = false
          raise ActiveRecord::Rollback
        end
      end

      setting = permission.setting || permission.build_setting
      setting.token = params[:token]
      setting.username = params[:username]
      unless setting.save
        success = false
        raise ActiveRecord::Rollback
      end
    end

    head :ok and return if success

    render json: { errors: [ 'Cannot authenticate' ] }, status: :unprocessable_entity
  end

  def forget
    current_user.server_provider_permission(@server_provider.id)&.destroy

    head :ok
  end

  def sync
    SyncJob.perform_later(SyncJob::SyncType::SERVER_PROVIDER, @server_provider.id)

    head :ok
  end

  def repositories
    render json: @server_provider.repositories.map { |repository| presented_entity(:repository, repository) }
  end

  private

  def server_provider_params
    params.require(:server_provider).permit(:name, :url)
  end

  def set_server_provider
    @server_provider = ServerProvider.find(params[:id])
  end
end
