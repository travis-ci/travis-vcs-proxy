# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  default from: 'from@example.com'
  layout 'mailer'

  def send_feedback
    @email = params[:email]
    @feedback = params[:feedback]
    mail(to: Settings.feedback_mail, subject: 'Account removed')
  end
end
