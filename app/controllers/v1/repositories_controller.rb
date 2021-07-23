# frozen_string_literal: true

class V1::RepositoriesController < ApplicationController
  before_action :require_authentication
  before_action :set_repository, only: [:show, :refs]

  def show
    render json: presented_entity(:repository, @repository)
  end

  def refs
    render json: @repository.refs.map { |ref| presented_entity(:full_ref, ref) }
  end

  def token
    head :bad_request and return if params[:username].blank? || params[:token].blank?

    permission = current_user.repository_permission(@repository.id)
    head :forbidden and return if permission.blank? || (!permission.owner? && !permission.admin?)

    begin
      ValidateP4Credentials.new(params[:username], params[:token], @repository.server_provider.url).call
    rescue ValidateP4Credentials::ValidationFailed
      render json: { errors: [ 'Cannot authenticate' ] }, status: :unprocessable_entity and return
    end

    permission.settings(:p4_host).username = params[:username]
    permission.token = params[:token]
    head :ok and return if permission.save

    render json: { errors: permission.errors }, status: :unprocessable_entity
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params[:id])
  end
end
