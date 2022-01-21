# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class Organization
        def initialize(organization, user)
          @organization = organization
          @user = user
        end

        def sync
          puts "SYNC ORG: #{@organization.inspect}"

          ActiveRecord::Base.transaction do
            puts "SYNC REPOS #{@organization.name}: #{@organization.remote_repositories.inspect}"
            sync_repositories(@organization.remote_repositories)

            @organization.users.each do |user|
              puts "sync.GETTING permission #{@organization.name} for: #{user.inspect} and sp: #{@organization.id}"
              next unless permission_setting = user.organization_permission(@organization.id).setting

              puts "SYNC REPOS #{@organization.name} FOR USER: #{permission_setting.username} #{@organization.remote_repositories.inspect}"
              sync_repositories(@organization.remote_repositories(permission_setting.username, permission_setting.token))
            end
          end
        end

        private

        def sync_repositories(repositories)
          repositories.each do |repository|
            repo = @organization.repositories.find_or_initialize_by(name: repository[:name])
            Travis::VcsProxy::Sync::Repository.new(repo, @user).sync
          end
        end
      end
    end
  end
end
