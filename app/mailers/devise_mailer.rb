    class DeviseMailer < Devise::Mailer
      attr_accessor :vcsproxy_link

      def initialize
        super
        @vcsproxy_link=Settings.web_url
      end
   end
