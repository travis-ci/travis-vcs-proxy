# frozen_string_literal: true

class V1::ServerProvidersController < ApplicationController
  include PaginatedCollection

  before_action :require_authentication
  before_action :set_server_provider, only: [:show, :update, :authenticate, :forget, :repositories, :sync]

  PROVIDER_KLASS = {
    'perforce' => P4ServerProvider
  }.freeze

  def create
    head :bad_request and return if params[:server_provider].blank? || !PROVIDER_KLASS.has_key?(params[:server_provider][:type])

    klass = PROVIDER_KLASS[params[:server_provider][:type]]
    render json: { errors: [ 'A server with this URL already exists.' ] }, status: :unprocessable_entity and return if klass.find_by(url: params[:server_provider][:url]).present?

    errors = []
    provider = nil
    ActiveRecord::Base.transaction do
      provider = klass.new(server_provider_params)
      unless provider.save
        errors = provider.errors
        raise ActiveRecord::Rollback
      end

      set_provider_credentials(provider, errors)

      unless current_user.set_server_provider_permission(provider.id, ServerProviderPermission::OWNER)
        errors << 'Cannot set permission for user'
        raise ActiveRecord::Rollback
      end
    end

    render json: presented_entity(:server_provider, provider) and return if errors.blank?

    render json: { errors: errors }, status: :unprocessable_entity
  end

  def show
    render json: presented_entity(:server_provider, @server_provider)
  end

  def update
    permission = current_user.server_provider_permission(@server_provider.id)
    head :forbidden and return if permission.blank? || !permission.owner?

    errors = []
    ActiveRecord::Base.transaction do
      unless @server_provider.update(server_provider_params)
        errors = @server_provider.errors
        raise ActiveRecord::Rollback
      end

      set_provider_credentials(@server_provider, errors)
    end

    head :ok and return if errors.blank?

    render json: { errors: errors }, status: :unprocessable_entity
  end

  def authenticate
    head :bad_request and return if params[:token].blank? || params[:username].blank?

    success = true
    ActiveRecord::Base.transaction do
      permission = current_user.server_provider_permissions.find_or_initialize_by(server_provider_id: @server_provider.id)
      unless permission.persisted?
        permission.permission = ServerProviderPermission::MEMBER
        unless permission.save
          success = false
          raise ActiveRecord::Rollback
        end
      end

      begin
        ValidateP4Credentials.new(params[:username], params[:token], @server_provider.url).call
      rescue ValidateP4Credentials::ValidationFailed => e
        success = false
        raise ActiveRecord::Rollback
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
    SyncJob.perform_later(SyncJob::SyncType::SERVER_PROVIDER, @server_provider.id, current_user.id)

    head :ok
  end

  def repositories
    order = params[:sort_by] == 'last_synced_at' ? 'DESC' : 'ASC'
    repositories = @server_provider.repositories
      .includes(:repository_permissions)
      .includes(:setting_objects)
      .order(params[:sort_by] => order)
    unless params[:filter].empty?
      repositories = repositories.where('name LIKE ?', "%#{params[:filter]}%")
    end

    render json: paginated_collection(:repositories, :repository, repositories.page(params[:page]).per(params[:limit]))
  end

  def by_url
    head :bad_request and return if params[:url].blank?

    render json: presented_entity(:server_provider, ServerProvider.find_by!(url: params[:url]))
  end

  def add_by_url
    head :bad_request and return if params[:url].blank?

    errors = []
    provider = ServerProvider.find_by!(url: params[:url])

    unless current_user.set_server_provider_permission(provider.id, ServerProviderPermission::MEMBER)
      errors << 'Cannot set permission for user'
      raise ActiveRecord::Rollback
    end

    render json: presented_entity(:server_provider, provider) and return if errors.blank?

    render json: { errors: errors }, status: :unprocessable_entity
  end

  private

  def server_provider_params
    params.require(:server_provider).permit(:name, :url)
  end

  def set_server_provider
    @server_provider = ServerProvider.includes(:server_provider_permissions).find(params[:id])
  end

  def set_provider_credentials(provider, errors)
    return if params[:server_provider][:username].blank? || params[:server_provider][:token].blank?

    begin
      ValidateP4Credentials.new(params[:server_provider][:username], params[:server_provider][:token], provider.url).call
    rescue ValidateP4Credentials::ValidationFailed => e
      success = false
      errors << 'Cannot authenticate'
      raise ActiveRecord::Rollback
    end

    provider.settings(:p4_host).username = params[:server_provider][:username]
    provider.token = params[:server_provider][:token]
    unless provider.save
      success = false
      errors << 'Cannot save credentials'
      raise ActiveRecord::Rollback
    end
  end
end
