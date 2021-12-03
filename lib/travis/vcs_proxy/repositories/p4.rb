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
          puts "REPOSITORIES! uname: #{@username}"
          puts " rundepots: #{p4.run_depots.inspect}"
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
          puts "BRANCHES! uname: #{@username}, repo: #{@repository.name}"
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
          puts "PERMISSIONS!"
          @permissions ||= users.each_with_object({}) do |user, memo|
            puts "user: #{user.inspect}"
            p = protects(user) if user
            puts "PROTECTS FOR #{user.inspect} AND repo : #{@repository.name}"
            if p
              values = p.detect{ |repo| repo['depotFile'] == "//#{@repository.name}/..."}
              values = p.detect{ |repo| repo['depotFile'] == "//..."} unless values
            end
            memo[user[:email]] = values['perm'] if values
            puts "setting perms for user #{user[:email].inspect} to #{memo[user[:email]].inspect} for repo: #{@repository.name}"
          rescue P4Exception => e
            puts e.message.inspect
          end
        end

        def file_contents(ref, path)
          p4.run_print("//#{@repository.name}/#{path}")[1]
        rescue P4Exception => e
          puts e.message.inspect
          file_contents_stream(ref, path)
        end

        def file_contents_stream(commit, path)
          return nil unless commit

          ref = Ref.find(commit.ref_id)
          p4.run_print("//#{@repository.name}/#{ref.name}/#{path}")[1] if ref
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

        def protects(user)
          token = token_for_user(user[:email])
          return nil unless token

          _p4 = ::P4.new
          _p4.charset = 'utf8'
          _p4.port = @url
          _p4.user = user[:name]
          _p4.password = token
          _p4.ticket_file = '/dev/null'
          _p4.connect
          _p4.run_trust('-y')
          puts "running protects for #{@url.inspect} and user: #{user[:name]}"
          result = _p4.run_protects
          puts "PROTECTS RESULT : #{result.inspect}"
          _p4.disconnect
          result
        end

        def token_for_user(email)
          return @repository.token if @repository.token&.length > 0

          user = User.find_by(email: email)
          puts "user: #{user.inspect}"
          return @repository.server_provider.token unless user

          puts "token from settings"
          setting = user.server_provider_permission(@repository.server_provider_id)&.setting
          setting.token if setting
        end

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

          puts "conn.running protects for #{@url.inspect} and user: #{@username}"
          @p4.run_protects

          @p4
        rescue P4Exception => e
          puts e.message.inspect
          #raise
        end
      end
    end
  end
end
