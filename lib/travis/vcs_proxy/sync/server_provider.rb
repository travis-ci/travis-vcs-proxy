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
          ActiveRecord::Base.transaction do
            sync_repositories(@server_provider.remote_repositories)

            @server_provider.users.each do |user|
              next unless permission_setting = user.server_provider_permission(@server_provider.id).setting
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
