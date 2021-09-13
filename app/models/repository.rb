# frozen_string_literal: true

class Repository < ApplicationRecord
  include P4HostSettings
  include EncryptedToken

  belongs_to :server_provider

  validates_presence_of :name, :url, :server_provider_id

  has_many :refs, dependent: :destroy
  has_many :permissions, class_name: 'RepositoryPermission', dependent: :delete_all
  has_many :users, through: :permissions
  has_many :commits, dependent: :destroy
  has_many :webhooks, dependent: :destroy

  def branches
    refs.branch
  end

  def tags
    refs.tag
  end

  def repo(username = nil, token = nil)
    server_provider.bare_repo(self, username, token)
  end

  def file_contents(ref, path)
    repo.file_contents(ref, path)
  end
end
