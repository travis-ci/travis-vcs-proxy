# frozen_string_literal: true

class ServerProviderSerializer < ApplicationSerializer
  PROVIDER_KLASS = {
    P4ServerProvider => 'perforce',
  }.freeze

  PERMISSION = {
    nil => '',
    'owner' => 'Owner',
    'member' => 'User',
  }.freeze

  attributes :id, :name, :url

  attribute(:type) { |server| PROVIDER_KLASS[server.type.constantize] }
  attribute(:username) { |server| server.settings(:p4_host).username }
  attribute(:permission) { |server, params| PERMISSION[params[:current_user].server_provider_permission(server.id)&.permission] }
end
