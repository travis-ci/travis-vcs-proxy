# frozen_string_literal: true

module Travis
  module VcsProxy
    class Syncer
      def initialize(user)
        @user = user
      end

      def sync_server_provider(server_provider)
        puts "SYNC server_provider: #{server_provider.inspect} \n: user: #{@user.inspect}"
        Sync::ServerProvider.new(server_provider, @user).sync
      end

      def sync_user
        puts "SYNC user: #{@user.inspect}"
        Sync::User.new(@user).sync
      end

      def sync_repository(repository)
        puts "SYNC repo: #{repository.inspect}   \n user:#{@user.inspect}"
        Sync::Repository.new(repository, @user).sync
      end
    end
  end
end
