# frozen_string_literal: true

class V1::Repositories::BranchesController < ApplicationController
  before_action :require_authentication
  before_action :set_repository
  before_action :set_branch, only: [:show]

  def index
    render json: @repository.branches.map { |branch| presented_entity(:ref, branch) }
  end

  def show
    render json: presented_entity(:ref, @branch)
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params[:repository_id])
  end

  def set_branch
    @branch = @repository.branches.find(params[:id])
  end
end
