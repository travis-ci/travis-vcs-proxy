# frozen_string_literal: true

module V1
  module Repositories
    class TokenController < ApplicationController
      before_action :require_authentication
      before_action :set_repository

      def get
        permission = current_user.repository_permission(@repository.id)
        head(:forbidden) && return if permission.blank?
        head(:forbidden) && return if permission.setting.blank? || permission.setting.token.blank?

        render json: { token: permission.setting.token, username: permission.setting.username }
      end

      def update # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        head(:bad_request) && return if params[:username].blank? || params[:token].blank?

        permission = current_user.repository_permission(@repository.id)
        head(:forbidden) && return if permission.blank?

        success = false
        begin
          success = UpdateRepositoryCredentials.new(@repository, authentication_params).call
        rescue UpdateRepositoryCredentials::ValidationFailed
          render(json: { errors: ['Cannot authenticate'] }, status: :unprocessable_entity) && (return)
        end

        head(:ok) && return if success

        render json: { errors: @repository.errors }, status: :unprocessable_entity
      end

      def destroy
        permission = current_user.repository_permission(@repository.id)
        head(:forbidden) && return if permission.blank?

        head(:ok) && return if UpdateRepositoryCredentials.new(@repository, {}).call

        render json: { errors: @repository.errors }, status: :unprocessable_entity
      end

      private

      def authentication_params
        params.permit(:username, :token, :svn_realm)
      end

      def set_repository
        @repository = current_user.repositories.find_by(id: params[:repository_id])
      end
    end
  end
end
