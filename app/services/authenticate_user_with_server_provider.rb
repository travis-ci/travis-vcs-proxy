# frozen_string_literal: true

class AuthenticateUserWithServerProvider
  def initialize(server_provider_permission, server_provider, params)
    @server_provider_permission = server_provider_permission
    @server_provider = server_provider
    @username = params[:username]
    @password = params[:token]
    @svn_realm = params[:svn_realm]
  end

  def call
    case @server_provider
    when P4ServerProvider then authenticate_p4
    when SvnServerProvider then authenticate_svn
    end
  end

  private

  def authenticate_p4
    begin
      ValidateP4Credentials.new(@username, @password, @server_provider.url).call
    rescue ValidateP4Credentials::ValidationFailed
      return false
    end

    setting = @server_provider_permission.setting || @server_provider_permission.build_setting
    setting.token = @password
    setting.username = @username
    setting.save
  end

  def authenticate_svn
    begin
      ValidateSvnCredentials.new(@username, @password, @server_provider.url, @svn_realm).call
    rescue ValidateSvnCredentials::ValidationFailed
      return false
    end

    setting = @server_provider_permission.setting || @server_provider_permission.build_setting
    setting.password = @password
    setting.username = @username
    setting.svn_realm = @svn_realm
    setting.save
  end
end
