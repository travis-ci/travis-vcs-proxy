# frozen_string_literal: true

module V1
  class RepositoriesController < ApplicationController
    before_action :require_authentication
    before_action :set_repository

    def show
      render json: presented_entity(:repository, @repository)
    end

    def refs
      render json: @repository.refs.map { |ref| presented_entity(:full_ref, ref) }
    end

    def content
      head(:bad_request) && return if params[:ref].blank? || params[:path].blank?

      result = @repository.file_contents(params[:ref], params[:path])
      render(json: { errors: ['Cannot render file'] }, status: :unprocessable_entity) && return if result.blank?

      render plain: result[1]
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
