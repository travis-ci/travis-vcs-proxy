class ApplicationMailer < ActionMailer::Base
  default from: Settings.mail_from
  layout 'mailer'
end
