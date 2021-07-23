# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class User
        def initialize(user)
          @user = user
        end

        def sync
          @user.server_providers.each do |server_provider|
            Travis::VcsProxy::Sync::ServerProvider.new(server_provider, @user).sync
          end
        end
      end
    end
  end
end
