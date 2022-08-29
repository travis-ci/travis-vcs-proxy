# frozen_string_literal: true

class UpdateRepositoryCredentials
  class ValidationFailed < StandardError; end
  class NoRights < StandardError; end

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
          ValidateP4Credentials.new(@username, @password, @entity.url, '').call
        rescue ValidateP4Credentials::ValidationFailed
          raise ValidationFailed
        end
      end

      s = settings(@username, @entity)
      if s
        s.username = @username
        s.token = @password
        s.save!
      end

    when 'svn'
      if @username.present? || @password.present?
        begin
          ValidateSvnCredentials.new(@username, @password, @entity.url, @svn_realm).call
        rescue ValidateSvnCredentials::ValidationFailed
          raise ValidationFailed
        end
      end

      s = settings(@username, @entity)
      if s
        s.username = @username
        s.token = @password
        s.svn_realm = @svn_realm
        s.save!
      end
    end
  end
end
