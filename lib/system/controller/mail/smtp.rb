require 'nkf'
class System::Controller::Mail::Smtp < ActionMailer::Base
  def default(mail_fr, mail_to, subject, message)
    from       mail_fr
    recipients mail_to
    subject    subject
    body       message
  end
end