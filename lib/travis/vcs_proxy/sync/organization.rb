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
            puts "SYNC REPOS #{@organization.name}: #{@organization.repositories.inspect}"
            sync_repositories(@organization.repositories)

            @organization.users.each do |user|
              puts "sync.GETTING permission #{@organization.name} for: #{user.inspect} and sp: #{@organization.id}"
              next unless user.organization_permission(@organization.id)

              puts "SYNC REPOS #{@organization.name} #{@organization.repositories.inspect}"
              sync_repositories(@organization.repositories)
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
