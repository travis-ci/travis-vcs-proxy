# frozen_string_literal: true

class AuthenticateUserWithServerProvider
  def initialize(server_provider_permission, server_provider, username, password)
    @server_provider_permission = server_provider_permission
    @server_provider = server_provider
    @username = username
    @password = password
  end

  def call
    case @server_provider
    when P4ServerProvider then authenticate_p4
    end
  end

  private

  def authenticate_p4
    begin
      ValidateP4Credentials.new(@username, @password, @server_provider.url).call
    rescue ValidateP4Credentials::ValidationFailed => e
      return false
    end

    setting = @server_provider_permission.setting || @server_provider_permission.build_setting
    setting.token = @password
    setting.username = @username
    setting.save
  end
end