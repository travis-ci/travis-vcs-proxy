# frozen_string_literal: true

class ServerProviderSerializer < ApplicationSerializer
  PROVIDER_KLASS = {
    P4ServerProvider => 'perforce',
    SvnServerProvider => 'svn',
  }.freeze

  PROVIDER_TYPE_KLASS = {
    P4ServerProvider => :p4_host,
    SvnServerProvider => :svn_host,
  }.freeze

  PERMISSION = {
    nil => '',
    'owner' => 'Owner',
    'member' => 'User',
  }.freeze

  attributes :id, :name, :url

  attribute(:type) { |server| PROVIDER_KLASS[server.type.constantize] }
  attribute(:username) { |server| server.settings(PROVIDER_TYPE_KLASS[server.type.constantize]).username }
  attribute(:permission) { |server, params| PERMISSION[params[:current_user]&.server_provider_permission(server.id)&.permission] }
end
