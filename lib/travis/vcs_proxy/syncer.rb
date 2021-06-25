# frozen_string_literal: true

module Travis
  module VcsProxy
    class Syncer
      def sync_server_provider(server_provider)
        Sync::ServerProvider.new(server_provider).sync
      end

      def sync_user(user)
        Sync::User.new(user).sync
      end

      def sync_repository(repository)
        Sync::Repository.new(repository).sync
      end
    end
  end
end
