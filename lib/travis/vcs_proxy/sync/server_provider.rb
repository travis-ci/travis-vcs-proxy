# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class ServerProvider
        def initialize(server_provider, user)
          @server_provider = server_provider
          @user = user
        end

        def sync
          puts "SYNC SP: #{@server_provider.inspect}"

          ActiveRecord::Base.transaction do

            puts "SYNC REPOS: #{@server_provider.remote_repositories.inspect}"
            sync_repositories(@server_provider.remote_repositories)

            @server_provider.users.each do |user|
              puts "sync.GETTING permission for: #{user.inspect} and sp: #{@server_provider.id}"
              next unless permission_setting = user.server_provider_permission(@server_provider.id).setting

              puts "SYNC REPOS FOR USER: #{permission_setting.username} #{@server_provider.remote_repositories.inspect}"
              sync_repositories(@server_provider.remote_repositories(permission_setting.username, permission_setting.token))
            end
          end
        end

        private

        def sync_repositories(repositories)
          repositories.each do |repository|
            repo = @server_provider.repositories.find_or_initialize_by(name: repository[:name])
            unless repo.persisted?
              repo.url = 'STUB'
              repo.save!
            end

            Travis::VcsProxy::Sync::Repository.new(repo, @user).sync
          end
        end
      end
    end
  end
end
