# frozen_string_literal: true
require 'P4'

class ValidateP4Credentials
  class ValidationFailed < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  def initialize(username, token, url)
    @username = username
    @token = token
    @url = url
  end

  def call
    file = Tempfile.new('p4ticket')
    file.write(@token)
    file.close

    ENV['P4TICKETS'] = file.path

    p4 = P4.new
    p4.charset = 'utf8'
    p4.port = @url
    p4.user = @username
    p4.connect
    p4.run_login

    nil
  rescue P4Exception => e
    raise ValidationFailed.new(e.message)
  ensure
    if file
      begin
        file.close
        file.unlink
      rescue
      end
    end

    ENV.delete('P4TICKETS')
  end
end