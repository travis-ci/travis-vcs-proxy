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
  attribute(:username) do |server|
    permission = server.server_provider_permissions&.first
    setting = permission&.setting || permission&.build_setting
    setting&.username || ''
  end
  attribute(:permission) { |server, _params| PERMISSION[server.server_provider_permissions&.first&.permission] }
end
