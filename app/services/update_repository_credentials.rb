# frozen_string_literal: true

class UpdateRepositoryCredentials
  class ValidationFailed < StandardError; end

  def initialize(entity, username, password)
    @entity = entity
    @username = username
    @password = password
  end

  def call # rubocop:disable Metrics/CyclomaticComplexity
    server_provider = case @entity
                      when Repository then @entity.server_provider
                      when ServerProvider then @entity
                      end

    case server_provider
    when P4ServerProvider
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
    end
  end
end
