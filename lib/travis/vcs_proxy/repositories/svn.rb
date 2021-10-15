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
          @user = User.find_by(email: @username)
          return [] unless @user

          @permissions = ::RepositoryPermission.where(user_id: @user.id)
          @repositories = []
          @permissions.each do |_perm|
            @repositories |= ::Repository.find_by(id: @perm.repository_id) if @permissions.permission
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
          xml_res = svn.log(@repository.name, nil, branch: branch_name, format: 'xml')
          return [] unless xml_res

          xml = Nokogiri::Xml(xml_res)
          result = xml.at_xpath('log')&.map do |entry|
            next unless email = user_map[entry.at_xpath('author')]
            next unless user = User.find_by(email: email)

            {
              sha: entry.at_xpath('revision'),
              user: user,
              message: entry.at_xpath('msg'),
              committed_at: Time.at(entry.at_xpath('date').to_i),
            }
          end
          result&.compact
        end

        def permissions
          @permissions ||= users.each_with_object({}) do |user, memo|
            memo[user[:email]] = p4.run_protects('-u', user[:name], '-M', "//#{@repository.name}/...").first['permMax']
          rescue P4Exception => e
            puts e.message.inspect
          end
        end

        def file_contents(ref, path)
          svn.content(@repository.name, path, branch: ref)
        end

        def commit_info(change_root, username)
          # TODO
          nil
        end
      end
    end
  end
end
