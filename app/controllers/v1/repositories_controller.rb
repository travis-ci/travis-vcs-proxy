# frozen_string_literal: true

module V1
  class RepositoriesController < ApplicationController
    before_action :require_authentication
    before_action :set_repository, except: %i[create update]

    def show
      render json: presented_entity(:repository, @repository)
    end

    def create
      errors = nil
      if params['repository']
        ActiveRecord::Base.transaction do
          @repository = Repository.new(
            name: params['repository']['name'],
            url: params['repository']['url'],
            server_provider_id: params['repository']['server_provider_id'],
            last_synced_at: Time.now
          )
          unless @repository.save
            errors = @repository.errors
            raise ActiveRecord::Rollback
          end
        end
        perm = current_user.repository_permissions.build(repository_id: @repository.id)
        perm.permission = 'admin'
        perm.save!
      end

      render json: presented_entity(:repository, @repository) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def refs
      render json: @repository.refs.map { |ref| presented_entity(:full_ref, ref) }
    end

    def content
      head(:bad_request) && return if params[:ref].blank? || params[:path].blank?

      ref, commit = params[:ref].split('@')
      if commit
        ref = Ref.find_by(name: ref, repository: @repository)
        commit = Commit.find_by(sha: commit, ref: ref)
      else
        commit = Commit.find_by(sha: ref, repository: @repository)
      end
      user_token = current_user.server_provider_permission(@repository.server_provider.id)&.setting

      result = @repository.file_contents(commit, params[:path])

      if result.blank? && !user_token.token.blank?
        repo = @repository.server_provider.bare_repo(@repository, user_token.username, user_token.token)
        result = repo.file_contents(commit, params[:path])
      end

      render(json: { errors: ['Cannot render file'] }, status: :unprocessable_entity) && return if result.blank?

      render plain: result
    end

    def sync
      SyncJob.perform_later(SyncJob::SyncType::REPOSITORY, @repository.id, current_user.id)

      head :ok
    end

    private

    def set_repository
      @repository = current_user.repositories.includes(:permissions).find(params[:id])
    end
  end
end
