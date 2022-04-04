# frozen_string_literal: true

class UpdateRepositoryCredentials
  class ValidationFailed < StandardError; end

  def initialize(entity, params)
    @entity = entity
    @username = params[:username]
    @password = params[:token]
    @svn_realm = params[:svn_realm]
  end

  def call # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    server_type = case @entity
                  when Repository then @entity.server_type
                  end

    case server_type
    when 'perforce'
      if @username.present? || @password.present?
        begin
          ValidateP4Credentials.new(@username, @password, server_provider.url).call
        rescue ValidateP4Credentials::ValidationFailed
          raise ValidationFailed
        end
      end

      @entity.settings(:p4_host).username = @username
      @entity.token = @password
      @entity.save

    when 'svn'
      if @username.present? || @password.present?
        begin
          ValidateSvnCredentials.new(@username, @password, server_provider.url, @svn_realm).call
        rescue ValidateSvnCredentials::ValidationFailed
          raise ValidationFailed
        end
      end

      @entity.settings(:svn_host).username = @username
      @entity.settings(:svn_host).svn_realm = @svn_realm
      @entity.token = @password
      @entity.save
    end
  end
end
