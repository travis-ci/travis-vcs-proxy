# frozen_string_literal: true

require 'nokogiri'

module Travis
  module VcsProxy
    module Repositories
      class Svn
        class PermissionNotFound < StandardError; end

        attr_accessor :svn

        def initialize(repository, url, username, token)
          @repository = repository
          @url = url
          @username = username
          @token = token
          @svn = SvnClient.new
          @svn.username = @username
          @svn.ssh_key = @token
          @svn.url = @url
        end

        def repositories
          @user = ServerProviderUserSetting.find_by(username: @username)&.permission&.user
          return [] unless @user

          @permissions = ::RepositoryPermission.where(user_id: @user.id)
          @repositories = []
          @permissions.each do |_perm|
            repo = ::Repository.find_by(id: _perm.repository_id) if _perm.permission
            @repositories.append(repo) if repo
          end
          @repositories
        end

        def branches
          @branches ||= svn.branches(@repository.name).map do |branch|
            {
              name: branch,
            }
          end
        end

        def users
          @users ||= svn.users(@repository.name).map do |user|

            {
              email: user,
              name: user,
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
          xml_res = svn.log(@repository.name, nil, branch: branch_name, format: 'xml')
          return [] unless xml_res

          xml = Nokogiri::XML(xml_res)
          result = xml.at_xpath('log')&.children.map do |entry|
            next unless uname = user_map[entry.at_xpath('author')&.text]

            puts uname
            user = ServerProviderUserSetting.find_by(username: uname)&.permission&.user
            next unless user

            {
              sha: entry.attribute('revision')&.value || '0',
              user: user,
              message: entry.at_xpath('msg')&.text,
              committed_at: Time.at(entry.at_xpath('date').text.to_i),
            }
          end
          result&.compact
        end

        def permissions
          @permissions ||= users.each_with_object({}) do |user, memo|
            memo[user[:email]] = 2
          end
        end

        def file_contents(ref, path)
          svn.content(@repository.name, path, branch: ref.ref.name, revision: ref.sha)
        end

        def commit_info(change_root, username)
          # TODO
          nil
        end
      end
    end
  end
end
