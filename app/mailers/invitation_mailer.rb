# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  default from: Settings.mail_from
  layout 'mailer'

  def send_invitation
    @email = params[:email]
    @organization = params[:organization]
    @invitation_link = params[:invitation_link]
    @vcsproxy_link = Settings.web_url
    mail(to: @email, subject: 'Organization invitation')
  end
end