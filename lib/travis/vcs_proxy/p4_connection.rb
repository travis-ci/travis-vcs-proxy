# frozen_string_literal: true
require 'P4'

module Travis
  module VcsProxy
    class P4Connection
      class PermissionNotFound < StandardError; end

      def initialize(url, username, token)
        @url = url
        @username = username
        @token = token
      end

      def repositories
        @repositories ||= p4.run_depots.map do |depot|
          {
            name: depot['name']
          }
        end
      rescue P4Exception => e
        puts e.message.inspect

        []
      end

      def branches(repository_name)
        @branches ||= p4.run_streams("//#{repository_name}/...").map do |stream|
          {
            name: stream['Stream']
          }
        end
      rescue P4Exception => e
        puts e.message.inspect

        []
      end

      def users
        @users ||= p4.run_users('-a').map do |user|
          next unless user['Email'].include?('@')

          {
            email: user['Email'],
            name: user['User']
          }
        end.compact
      rescue P4Exception => e
        puts e.message.inspect

        []
      end

      def permissions(repository_name)
        @permissions ||= users.each_with_object({}) do |user, memo|
          memo[user[:email]] = p4.run_protects('-u', user[:name], '-M', "//#{repository_name}/...").first['permMax']
        end
      rescue P4Exception => e
        puts e.message.inspect

        {}
      end

      def file_contents(repository_name, ref, path)
        p4.run_print("//#{repository_name}/#{ref}/#{path}")
      rescue P4Exception => e
        puts e.message.inspect
        nil
      end

      private

      def p4
        return @p4 if defined?(@p4)

        file = Tempfile.new('p4ticket')
        file.write(@token)
        file.close

        p4 = P4.new
        p4.charset = 'utf8'
        p4.port = @url
        p4.user = @username
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
