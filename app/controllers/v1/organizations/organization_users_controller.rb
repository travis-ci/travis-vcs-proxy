# frozen_string_literal: true

module V1
  module Organizations
    class OrganizationUsersController < ApplicationController
      before_action :require_authentication

      before_action :set_organization, only: %i[update authenticate forget repositories sync]

      def add
        result = set_permissions(params[:organization_id], params[:user_id], params[:organization_user][:permission])

        head(result) && return if result

        render(json: presented_entity(:organization, @organization))
      end

      def update
        result = set_permissions(params[:organization_id], params[:user_id], params[:organization_user][:permission])

        head(result) && return if result

        render(json: presented_entity(:organization, @organization))
      end

      def remove
        org_permissions = OrganizationPermission.where(organization_id: params[:organization_id])
        head(:forbidden) && return if org_permissions.count <= 1

        head(:forbidden) && return unless OrganizationPermission.find_by(organization_id: params[:organization_id], user_id: current_user.id)&.permission == 'owner'

        User.find(params[:user_id])&.remove_organization_permission(params[:organization_id])

        organization = Organization.includes(:organization_permissions).find(params[:organization_id])
        organization&.repositories&.each do |repo|
          RepositoryPermission.find_by(user_id: params[:user_id], repository_id: repo.id)&.destroy
        end
      end

      private

      def set_permissions(org_id, user_id, role)
        return :forbidden unless OrganizationPermission.find_by(organization_id: org_id, user_id: current_user.id)&.permission == 'owner'

        return :forbidden if current_user.id == user_id.to_i && OrganizationPermission.where(organization_id: org_id).count <= 1

        User.find(user_id)&.set_organization_permission(org_id, OrganizationPermission.permissions[role])
        false
      rescue # rubocop:disable Style/RescueStandardError
        :unprocessable_entity
      end

      def set_organization
        @organization = Organization.includes(:organization_permissions).find(params[:organization_id])
      end
    end
  end
end
