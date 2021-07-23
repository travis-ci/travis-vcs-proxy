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
            server_provider_username = @server_provider.settings(:p4_host).username
            server_provider_token = @server_provider.token
            if server_provider_username.present? && server_provider_token.present?
              connection = Travis::VcsProxy::P4Connection.new(@server_provider.url, server_provider_username, server_provider_token)
              sync_connection_data(connection)
              return
            end

            @server_provider.users.each do |user|
              next unless permission_setting = user.server_provider_permission(@server_provider.id).setting
              connection = Travis::VcsProxy::P4Connection.new(@server_provider.url, permission_setting.username, permission_setting.token)
              sync_connection_data(connection)
            end
          end
        end

        private

        def sync_connection_data(connection)
          repos = connection.repositories.map do |repository|
            repo = @server_provider.repositories.find_or_initialize_by(name: repository[:name])
            unless repo.persisted?
              repo.url = 'STUB'
              repo.save!
            end

            repo
          end

          repos.each do |repo|
            Travis::VcsProxy::Sync::Repository.new(repo, @user).sync
          end
        end
      end
    end
  end
end
