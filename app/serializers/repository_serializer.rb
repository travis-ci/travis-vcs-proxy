# frozen_string_literal: true

class RepositorySerializer < ApplicationSerializer
  attributes :id, :name, :url, :token, :last_synced_at, :server_provider_id

  attributes(:permission) do |repo, params|
    params[:current_user].repository_permission(repo.id).permission
  end
end
