# frozen_string_literal: true

require 'nokogiri'

module Travis
  module VcsProxy
    module Repositories
      class Svn
        class PermissionNotFound < StandardError; end

        attr_accessor :svn

        def initialize(server_provider, repository, url, username, token)
          @server_provider = server_provider
          @repository = repository
          @url = url
          @username = username
          @token = token
          @svn = SvnClient.new
          @svn.username = @username
          @svn.ssh_key = @token
          @svn.url = @url
        end


        def repositories(server_provider_id = nil)
          @user = get_user(server_provider_id, @username)
          return [] unless @user

          @permissions = ::RepositoryPermission.where(user_id: @user.id)
          @repositories = []
          @permissions.each do |_perm|
            repo = ::Repository.find_by(id: _perm.repository_id, server_provider_id: server_provider_id) if _perm.permission
            @repositories.append(repo) if repo
          end
          @repositories
        end

        def branches
          @svn.ssh_key = @repository.token
          @svn.url = @repository.url
          @branches ||= svn.branches(@repository.name).map do |branch|
            {
              name: branch,
            }
          end
        end

        def users
          @svn.ssh_key = @repository.token
          @svn.url = @repository.url
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
          @svn.ssh_key = @repository.token
          @svn.url = @repository.url
          user_map = users.each_with_object({}) do |user, memo|
            memo[user[:name]] = user[:email]
          end
          xml_res = svn.log(@repository.name, nil, branch: branch_name, format: 'xml')

          return [] unless xml_res

          xml = Nokogiri::XML(xml_res)
          result = xml.at_xpath('log')&.children.map do |entry|

            next unless uname = user_map[entry.at_xpath('author')&.text]

            user = get_user(@repository.server_provider.id, uname)

            next unless user

            {
              sha: entry.attribute('revision')&.value || '0',
              user: user,
              message: entry.at_xpath('msg')&.text,
              committed_at: DateTime.parse(entry.at_xpath('date').text),
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
          svn.url = @repository.url
          svn.content(@repository.name, path, branch: ref.ref.name, revision: ref.sha)
        end

        def commit_info(change_root, username, server_provider_id)
          user = get_user(server_provider_id, username)
          repo_name, branch = change_root.split('@')

          {
            repository_name: repo_name,
            ref: branch,
            email: user.email,
          }
        end

        def get_user(server_provider_id, username)
          user = nil
          ServerProviderUserSetting.where(username: username)&.each do |setting|
            if setting.permission&.server_provider_id == server_provider_id
              user = setting.permission.user
            end
          end
          user
      end
    end
  end
end
