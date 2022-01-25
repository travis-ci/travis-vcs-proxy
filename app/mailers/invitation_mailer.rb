# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  default from: 'from@example.com'
  layout 'mailer'

  def send_invitation
    @email = params[:email]
    @organization = params[:organization]
    @invitation_link = params[:invitation_link]
    mail(to: @email, subject: 'Organization invitation')
  end
end
