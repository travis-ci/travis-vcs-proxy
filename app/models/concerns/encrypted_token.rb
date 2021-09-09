# frozen_string_literal: true

module EncryptedToken
  extend ActiveSupport::Concern

  def encrypted_token(token_value)
    encryptor.encrypt_and_sign(token_value)
  end

  def decrypted_token(token_value)
    encryptor.decrypt_and_verify(token_value)
  end

  private

  def encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(Settings.p4_token_encryption_key)
  end
end
