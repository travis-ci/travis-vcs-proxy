# frozen_string_literal: true

module V1
  module Repositories
    class CommitsController < ApplicationController
      before_action :require_authentication
      before_action :set_repository
      before_action :set_branch, only: [:index]
      before_action :set_commit, only: [:show]

      def index
        render json: @branch.commits.order('committed_at DESC').map { |commit| presented_entity(:commit, commit) }
      end

      def show
        render json: presented_entity(:commit, @commit)
      end

      private

      def set_repository
        @repository = current_user.repositories.find(params[:repository_id])
      end

      def set_branch
        @branch = @repository.branches.find_by!(name: params[:branch])
      end

      def set_commit
        @commit = @repository.commits.find_by!(sha: params[:id])
      end
    end
  end
end
