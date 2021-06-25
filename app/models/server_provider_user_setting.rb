# frozen_string_literal: true
require 'P4'

class ServerProviderUserSetting < ApplicationRecord
  belongs_to :permission, class_name: 'ServerProviderPermission', foreign_key: :server_provider_user_id
  validates_presence_of :username, :value, :server_provider_user_id

  validate :validate_connection

  def token=(token)
    self.value = encryptor.encrypt_and_sign(token)
  end

  def token
    encryptor.decrypt_and_verify(value)
  end

  private

  def encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(Settings.p4_token_encryption_key)
  end

  def validate_connection
    file = Tempfile.new("p4ticket_#{id}")
    file.write(token)
    file.close

    ENV['P4TICKETS'] = file.path

    p4 = P4.new
    p4.charset = 'utf8'
    p4.port = permission.server_provider.url
    p4.user = username
    p4.connect
    p4.run_login
  rescue P4Exception => e
    puts e.message.inspect
    errors.add(:base, 'Connection failed')
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
