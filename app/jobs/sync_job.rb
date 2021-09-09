# frozen_string_literal: true

require 'travis/vcs_proxy/syncer'

class SyncJob < ApplicationJob
  class SyncType
    SERVER_PROVIDER = 1
    REPOSITORY = 2
    USER = 3
  end

  queue_as :default

  def perform(sync_type, id, user_id = nil)
    user = user_id.present? ? User.find(user_id) : User.find(id)
    syncer = Travis::VcsProxy::Syncer.new(user)
    case sync_type
    when SyncType::SERVER_PROVIDER then syncer.sync_server_provider(ServerProvider.find(id))
    when SyncType::REPOSITORY then syncer.sync_repository(Repository.find(id))
    when SyncType::USER then syncer.sync_user
    end
  end
end
