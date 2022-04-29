# frozen_string_literal: true

module Travis
  module VcsProxy
    class Syncer
      def initialize(user)
        @user = user
      end

      def sync_organization(organization)
        puts "SYNC organization: #{organization.inspect} \n: user: #{@user.inspect}"
        Sync::Organization.new(organization, @user).sync
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
