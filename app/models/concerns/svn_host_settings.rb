# frozen_string_literal: true

module SvnHostSettings
  extend ActiveSupport::Concern

  included do
    has_settings(persistent: true) do |s|
      s.key :svn_host, defaults: { username: '', token: '', svn_realm: '' }
    end

    def token=(pass_value)
      settings(:svn_host).token = pass_value.blank? ? pass_value : encrypted_token(pass_value)
    end

    def token
      tok = settings(:svn_host).token
      return tok if tok.blank?

      decrypted_token(tok)
    end
  end
end
