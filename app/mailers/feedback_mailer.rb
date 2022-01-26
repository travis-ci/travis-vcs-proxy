# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  default from: Settings.mail_from
  layout 'mailer'

  def send_feedback
    @email = params[:email]
    @feedback = params[:feedback]
    mail(to: Settings.feedback_mail, subject: 'Account removed')
  end
end
