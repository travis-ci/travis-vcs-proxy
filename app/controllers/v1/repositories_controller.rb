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

  private

  def set_repository
    @repository = current_user.repositories.find(params[:id])
  end
end
