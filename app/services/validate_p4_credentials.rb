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
    p4 = P4.new
    p4.charset = 'utf8'
    p4.port = @url
    p4.user = @username
    p4.password = @token
    p4.ticket_file = '/dev/null'
    p4.connect
    p4.run_trust('-y')
    p4.run_protects

    nil
  rescue P4Exception => e
    raise ValidationFailed, e.message
  ensure
    if file
      begin
        file.close
        file.unlink
      rescue StandardError => e
        puts e.message.inspect
      end
    end

    ENV.delete('P4TICKETS')
  end
end
