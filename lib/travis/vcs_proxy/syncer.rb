# frozen_string_literal: true

module Travis
  module VcsProxy
    class Syncer
      def initialize(user)
        @user = user
      end

      def sync_server_provider(server_provider)
        Sync::ServerProvider.new(server_provider, @user).sync
      end

      def sync_user
        Sync::User.new(@user).sync
      end

      def sync_repository(repository)
        Sync::Repository.new(repository, @user).sync
      end
    end
  end
end
