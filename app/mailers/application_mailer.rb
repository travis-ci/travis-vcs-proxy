# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Settings.mail_from
  layout 'mailer'
  attr_accessor :vcsproxy_link

  def initialize(params ={})
    super
    @vcsproxy_link = params.fetch(:vcsproxy_link, Settings.web_url)
    @travisci_link = params.fetch(:travisci_link, Settings.travis_url)
    @support_mail = params.fetch(:support_mail, 'beta.support@travis-ci.com')
    @contact_mail = params.fetch(:contact_mail, 'contact@travis-ci.com')
  end


end
