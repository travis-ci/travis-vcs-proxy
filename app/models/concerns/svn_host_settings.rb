# frozen_string_literal: true

module SvnHostSettings
  extend ActiveSupport::Concern

  included do

    def token=(pass_value)
      settings(:svn_host).password = pass_value.blank? ? pass_value : encrypted_token(pass_value)
    end

    def token
      tok = settings(:svn_host).password
      return tok if tok.blank?

      decrypted_token(tok)
    end
  end
end
