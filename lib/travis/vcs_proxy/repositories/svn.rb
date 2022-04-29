# frozen_string_literal: true

require 'nokogiri'

module Travis
  module VcsProxy
    module Repositories
      class Svn
        class PermissionNotFound < StandardError; end

        attr_accessor :svn

        def initialize(repository, username, token)
          @repository = repository
          @url = repository.url
          @username = username
          @token = token
          @svn = SvnClient.new
          @svn.username = @username
          @svn.ssh_key = @token
          @svn.url = @url
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
          @svn.ssh_key = @token
          @svn.url = @repository.url
          user_map = users.each_with_object({}) do |user, memo|
            memo[user[:name]] = user[:email]
          end
          xml_res = svn.log(@repository.name, nil, branch: branch_name, format: 'xml')

          return [] unless xml_res

          xml = Nokogiri::XML(xml_res)
          result = xml.at_xpath('log')&.children&.map do |entry|
            next unless uname = user_map[entry.at_xpath('author')&.text]

            user = get_user(@repository.id, uname)

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

        def commit_info(change_root, username, repository_id)
          user = get_user(repository_id, username)
          repo_name, branch = change_root.split('@')

          {
            repository_name: repo_name,
            ref: branch,
            email: user.email,
          }
        end

        def get_user(repository_id, username)
          user = nil
          RepositoryUserSetting.where(username: username)&.each do |setting|
            if setting.permission&.repository_id == repository_id
              user = setting.permission.user
            end
          end
          user
        end
      end
    end
  end
end
