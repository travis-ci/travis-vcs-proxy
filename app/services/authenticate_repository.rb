# frozen_string_literal: true

class AuthenticateRepository
  def initialize(repository_permission, repository, params)
    @repository_permission = server_provider_permission
    @repository = repository
    @username = params[:username]
    @password = params[:token]
    @svn_realm = params[:svn_realm]
  end

  def call
    case @repository.server_type
    when 'perforce' then authenticate_p4
    when 'svn' then authenticate_svn
    end
  end

  private

  def authenticate_p4
    begin
      ValidateP4Credentials.new(@username, @password, @repository.url).call
    rescue ValidateP4Credentials::ValidationFailed
      return false
    end

    setting = @repository_permission.setting || @repository_permission.build_setting
    setting.token = @password
    setting.username = @username
    setting.save
  end

  def authenticate_svn
    begin
      ValidateSvnCredentials.new(@username, @password, @repository.url, @svn_realm).call
    rescue ValidateSvnCredentials::ValidationFailed
      return false
    end

    setting = @repository_permission.setting || @repository_permission.build_setting
    setting.token = @password
    setting.username = @username
    setting.save
    @server_provider.settings(:svn_host).svn_realm = @svn_realm
  end
end
