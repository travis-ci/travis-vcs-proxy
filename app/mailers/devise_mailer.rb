# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  attr_accessor :vcsproxy_link

  def initialize
    super
    @vcsproxy_link = Settings.web_url
    @travisci_link = Settings.travis_url
    @support_mail = Settings.support_mail
    @contact_mail = Settings.contact_mail 
  end
end
