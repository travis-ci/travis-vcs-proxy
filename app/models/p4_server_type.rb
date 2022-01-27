# frozen_string_literal: true

class P4ServerType < ServerType
  include EncryptedToken

  def self.bare_repo(repository = nil, username = nil, password = nil)
    Travis::VcsProxy::Repositories::P4.new(repository, username, password)
  end

  def commit_info_from_webhook(payload)
    return unless payload.key?(:change_root) && payload.key?(:username)

    bare_repo.commit_info(payload[:change_root], payload[:username])
  end

  def provider_type
    'perforce'
  end

  def host_type
    :p4_host
  end

  def default_branch
    'master'
  end
end
