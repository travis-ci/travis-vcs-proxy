# frozen_string_literal: true

class RepositoryPermission < ApplicationRecord
  include P4HostSettings
  include EncryptedToken

  belongs_to :repository
  belongs_to :user

  enum permission: [ :read, :write, :admin, :super ]
end
