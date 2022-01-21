# frozen_string_literal: true

class OrganizationSerializer < ApplicationSerializer
  PERMISSION = {
    nil => '',
    'owner' => 'Owner',
    'member' => 'User',
  }.freeze

  attributes :id, :name, :description, :listener_token
  attribute(:permission) { |org, params| PERMISSION[params[:current_user]&.organization_permission(org.id)&.permission] }
end
