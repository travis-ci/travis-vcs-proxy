# frozen_string_literal: true

class RepositorySerializer < ApplicationSerializer
  attributes :id, :name, :url, :token, :last_synced_at, :server_provider_id

  attributes(:permission) { |repo, params| params[:current_user].repository_permission(repo.id)&.permission }
  attributes(:default_branch) { |repo| repo.server_provider.default_branch }
  attributes(:url) { |repo| URI.join(Settings.web_url, "servers/#{repo.server_provider_id}") }
  attributes(:owner) do |repo|
    {
      id: repo.server_provider.id,
    }
  end
  attributes(:slug) { |repo| "#{repo.server_provider.name}/#{repo.name}" }
  attributes(:server_type) { |repo| repo.server_provider.provider_type }
end
