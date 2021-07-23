# frozen_string_literal: true

module P4HostSettings
  extend ActiveSupport::Concern

  included do
    has_settings(persistent: true) do |s|
      s.key :p4_host, defaults: { username: '', token: '' }
    end

    def token=(token_value)
      settings(:p4_host).token = token_value.blank? ? token_value : encrypted_token(token_value)
    end

    def token
      tok = settings(:p4_host).token
      return tok if tok.blank?

      decrypted_token(tok)
    end
  end
end