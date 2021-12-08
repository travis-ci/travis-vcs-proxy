# frozen_string_literal: true

module V1
  class ServerProvidersController < ApplicationController
    include PaginatedCollection

    before_action :require_authentication
    before_action :set_server_provider, only: %i[show update authenticate forget repositories sync]

    PROVIDER_KLASS = {
      'perforce' => P4ServerProvider,
      'svn' => ::SvnServerProvider,
    }.freeze

    def create # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if params[:server_provider].blank? || !PROVIDER_KLASS.key?(params[:server_provider][:type])
        head(:bad_request) && return
      end

      klass = PROVIDER_KLASS[params[:server_provider][:type]]
      if klass.find_by(url: params[:server_provider][:url]).present?
        render(json: { errors: ['A server with this URL already exists.'] }, status: :unprocessable_entity) && return
      end

      errors = []
      provider = nil
      ActiveRecord::Base.transaction do
        provider = klass.new(server_provider_params)
        unless provider.save
          errors = provider.errors
          raise ActiveRecord::Rollback
        end

        set_provider_credentials(provider, errors)

        unless current_user.set_server_provider_permission(provider.id, ServerProviderPermission.permissions[:owner])
          errors << 'Cannot set permission for user'
          raise ActiveRecord::Rollback
        end
      end

      render(json: presented_entity(:server_provider, provider)) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def show
      render json: presented_entity(:server_provider, @server_provider)
    end

    def update # rubocop:disable Metrics/CyclomaticComplexity
      permission = current_user.server_provider_permission(@server_provider.id)
      head(:forbidden) && return if permission.blank? || !permission.owner?

      errors = []
      ActiveRecord::Base.transaction do
        unless @server_provider.update(server_provider_params)
          errors = @server_provider.errors
          raise ActiveRecord::Rollback
        end

        set_provider_credentials(@server_provider, errors)

      end

      head(:ok) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def authenticate # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      head(:bad_request) && return if params[:token].blank? || params[:username].blank?

      success = true
      ActiveRecord::Base.transaction do
        permission = current_user.server_provider_permissions.find_or_initialize_by(server_provider_id: @server_provider.id)
        unless permission.persisted?
          permission.permission = ServerProviderPermission.permissions[:member]
          unless permission.save
            success = false
            raise ActiveRecord::Rollback
          end
        end

        unless AuthenticateUserWithServerProvider.new(permission, @server_provider, authentication_params).call
          success = false
          raise ActiveRecord::Rollback
        end
      end

      head(:ok) && return if success

      render json: { errors: ['Cannot authenticate'] }, status: :unprocessable_entity
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
                                     .includes(:permissions)
                                     .includes(:setting_objects)
      repositories = repositories.order(params[:sort_by] => order) if params[:sort_by].present?
      repositories = repositories.where('name LIKE ?', "%#{params[:filter]}%") if params[:filter].present?

      render json: paginated_collection(:repositories, :repository, repositories.page(params[:page]).per(params[:limit]))
    end

    def by_url
      head(:bad_request) && return if params[:url].blank?

      render json: presented_entity(:server_provider, ServerProvider.find_by!(url: params[:url]))
    end

    def add_by_url
      head(:bad_request) && return if params[:url].blank?

      errors = []
      provider = ServerProvider.find_by!(url: params[:url])

      unless current_user.set_server_provider_permission(provider.id, ServerProviderPermission.permissions[:member])
        errors << 'Cannot set permission for user'
        raise ActiveRecord::Rollback
      end

      render(json: presented_entity(:server_provider, provider)) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    private

    def server_provider_params
      params.require(:server_provider).permit(:name, :url)
    end

    def authentication_params
      params.permit(:username, :token, :svn_realm)
    end

    def server_provider_authentication_params
      params.require(:server_provider).permit(:username, :token, :svn_realm)
    end

    def set_server_provider
      @server_provider = ServerProvider.includes(:server_provider_permissions).find(params[:id])
    end

    def set_provider_credentials(provider, errors)
      return if params[:server_provider][:username].blank? || params[:server_provider][:token].blank?

      success = false
      begin
        success = UpdateRepositoryCredentials.new(provider, server_provider_authentication_params).call
      rescue UpdateRepositoryCredentials::ValidationFailed
        errors << 'Cannot authenticate'
        raise ActiveRecord::Rollback
      end

      return if success

      errors << 'Cannot save credentials'
      raise ActiveRecord::Rollback
    end
  end
end
