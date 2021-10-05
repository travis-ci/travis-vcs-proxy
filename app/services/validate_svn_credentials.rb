# frozen_string_literal: true

class ValidateSvnCredentials
  class ValidationFailed < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  def initialize(username, password, url, svn_realm = '')
    @username = username
    @password = password
    @url = url
    @svn_realm = svn_realm
  end

  def call
    raise ValidationFailed, e.message unless @username && @password

    true
  end
end
