# frozen_string_literal: true

class RepositorySerializer < ApplicationSerializer

  SERVER_TYPE_KLASS = {
    'perforce' => :p4_host,
    'svn' => :svn_host,
  }.freeze

  DEFAULT_BRANCH = {
    'perforce' => 'main',
    'svn' => 'trunk'
  }.freeze

  attributes :id, :name, :display_name, :url, :server_type, :last_synced_at, :owner_id, :url

  attributes(:permission) { |repo, params| params[:current_user]&.repository_permission(repo.id)&.permission }
  attributes(:token) { |repo, params| params[:current_user]&.repository_permission(repo.id)&.setting&.token }
  attributes(:username) { |repo, params| params[:current_user]&.repository_permission(repo.id)&.setting&.username }
  attributes(:default_branch) { |repo| DEFAULT_BRANCH[repo.server_type] }
  attributes(:owner) do |repo|
    {
      id: repo.owner_id,
      type: repo.owner_type
    }
  end
  attribute(:type) { |repo| repo.server_type }
  attributes(:slug) { |repo| "#{repo.ownerName }/#{repo.name}" }
  attributes(:source_url) { |repo| repo.url}
end
