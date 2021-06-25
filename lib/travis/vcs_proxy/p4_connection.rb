# frozen_string_literal: true
require 'P4'

module Travis
  module VcsProxy
    class P4Connection
      class PermissionNotFound < StandardError; end

      def initialize(server_provider, user, token)
        @server_provider = server_provider
        @user = user
        @server_provider_permission = user.server_provider_permission(server_provider.id)
        raise PermissionNotFound if @server_provider_permission.blank?
        @token = token
      end

      def repositories
        p4.run_depots.map do |depot|
          {
            name: depot['name']
          }
        end
      rescue P4Exception => e
        puts e.message.inspect

        []
      end

      def branches(repository_name)
        p4.run_streams("//#{repository_name}/...").map do |stream|
          {
            name: stream['Stream']
          }
        end
      rescue P4Exception => e
        puts e.message.inspect

        []
      end

      private

      def p4
        return @p4 if defined?(@p4)

        file = Tempfile.new("p4ticket_#{@server_provider.id}_#{@user.id}")
        file.write(@token)
        file.close

        p4 = P4.new
        p4.charset = 'utf8'
        p4.port = @server_provider.url
        p4.user = @server_provider_permission.setting.username
        p4.connect
        p4.run_login

        p4
      rescue P4Exception => e
        puts e.message.inspect
        raise
      ensure
        file.unlink if file
        ENV.delete('P4TICKETS')
      end
    end
  end
end
