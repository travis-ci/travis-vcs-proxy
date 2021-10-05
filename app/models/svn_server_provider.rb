# frozen_string_literal: true

class SvnServerProvider < ServerProvider
  include SvnHostSettings
  include EncryptedToken

  def bare_repo(repository = nil, username = nil, password = nil)
    if username.present? && password.present?
      repo_token = password
    elsif repository.present? && repository.settings(:svn_host).username.present?
      username = repository.settings(:svn_host).username
      repo_token = repository.token
    else
      puts settings(:svn_host).inspect.to_s
      username = settings(:svn_host).username
      puts "uname: #{username.inspect}"
      puts "token: #{token.inspect}"
      repo_token = token
    end

    Travis::VcsProxy::Repositories::Svn.new(repository, url, username, repo_token)
  end

  def remote_repositories(username = nil, token = nil)
    bare_repo(nil, username, token).repositories
  end

  def commit_info_from_webhook(payload)
    return unless payload.key?(:change_root) && payload.key?(:username)

    bare_repo.commit_info(payload[:change_root], payload[:username])
  end

  def provider_type
    'svn'
  end

  def default_branch
    'master'
  end
end
