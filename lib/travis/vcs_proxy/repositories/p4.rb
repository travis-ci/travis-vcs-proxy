# frozen_string_literal: true

require 'P4'

module Travis
  module VcsProxy
    module Repositories
      class P4
        class PermissionNotFound < StandardError; end

        def initialize(repository, url, username, token)
          @repository = repository
          @url = url
          @username = username
          @token = token
        end

        def repositories
          @repositories ||= p4.run_depots.map do |depot|
            {
              name: depot['name'],
            }
          end
        rescue P4Exception => e
          puts e.message.inspect

          []
        end

        def branches
          @branches ||= p4.run_streams("//#{@repository.name}/...").map do |stream|
            {
              name: stream['Stream'],
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
              name: user['User'],
            }
          end.compact
        rescue P4Exception => e
          puts e.message.inspect

          []
        end

        def commits(branch_name)
          user_map = users.each_with_object({}) do |user, memo|
            memo[user[:name]] = user[:email]
          end
          p4.run_changes('-l', "//#{@repository.name}/#{branch_name}/...").map do |change|
            next unless email = user_map[change['user']]
            next unless user = User.find_by(email: email)

            {
              sha: change['change'],
              user: user,
              message: change['desc'],
              committed_at: Time.at(change['time'].to_i),
            }
          end.compact
        end

        def permissions
          @permissions ||= users.each_with_object({}) do |user, memo|
            memo[user[:email]] = p4.run_protects('-u', user[:name], '-M', "//#{@repository.name}/...").first['permMax']
          rescue P4Exception => e
            puts e.message.inspect
          end
        end

        def file_contents(ref, path)
          p4.run_print("//#{@repository.name}/#{path}")
        rescue P4Exception => e
          puts e.message.inspect

          nil
        end

        def commit_info(change_root, username)
          matches = change_root.match(%r{\A//([^/]+)/([^/]+)})
          return if matches.nil?

          {
            repository_name: matches[1],
            ref: matches[2],
            email: p4.run_user('-o', username).first['Email'].encode('utf-8'),
          }
        rescue P4Exception => e
          puts e.message.inspect

          nil
        end

        private

        def p4
          return @p4 if defined?(@p4)

          @p4 = ::P4.new
          @p4.charset = 'utf8'
          @p4.port = @url
          @p4.user = @username
          @p4.password = @token
          @p4.ticket_file = '/dev/null'
          @p4.connect
          @p4.run_trust('-y')
          @p4.run_protects

          @p4
        rescue P4Exception => e
          puts e.message.inspect
          raise
        end
      end
    end
  end
end
