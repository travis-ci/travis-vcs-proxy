# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class User
        def initialize(user)
          @user = user
        end

        def sync
          @user.organizations.each do |organization|
            Travis::VcsProxy::Sync::Organization.new(organization, @user).sync
          end
        end
      end
    end
  end
end
