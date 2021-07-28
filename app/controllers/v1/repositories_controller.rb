# frozen_string_literal: true

class V1::RepositoriesController < ApplicationController
  before_action :require_authentication
  before_action :set_repository

  def show
    render json: presented_entity(:repository, @repository)
  end

  def refs
    render json: @repository.refs.map { |ref| presented_entity(:full_ref, ref) }
  end

  def content
    head :bad_request and return if params[:ref].blank? || params[:path].blank?

    connection = Travis::VcsProxy::P4Connection.new(@repository.server_provider.url, @repository.server_provider.settings(:p4_host).username, @repository.server_provider.token)

    result = connection.file_contents(@repository.name, params[:ref], params[:path])
    render json: { errors: [ 'Cannot render file' ] }, status: :unprocessable_entity and return if result.blank?

    render plain: result[1]
  end

  def sync
    SyncJob.perform_later(SyncJob::SyncType::REPOSITORY, @repository.id, current_user.id)

    head :ok
  end

  private

  def set_repository
    @repository = current_user.repositories.includes(:repository_permissions).find(params[:id])
  end
end
