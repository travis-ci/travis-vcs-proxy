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

  def sync
    SyncJob.perform_later(SyncJob::SyncType::REPOSITORY, @repository.id, current_user.id)

    head :ok
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params[:id])
  end
end
