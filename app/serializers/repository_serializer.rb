# frozen_string_literal: true

class RepositorySerializer < ApplicationSerializer
  attributes :id, :name, :url, :token, :last_synced_at, :server_provider_id

  attributes(:permission) do |repo|
    repo.repository_permissions&.first&.permission
  end
end
