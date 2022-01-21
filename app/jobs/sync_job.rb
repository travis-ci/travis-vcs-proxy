# frozen_string_literal: true

require 'travis/vcs_proxy/syncer'

class SyncJob < ApplicationJob
  class SyncType
    ORGANIZATION = 1
    REPOSITORY = 2
    USER = 3
  end

  queue_as :default

  def perform(sync_type, id, user_id = nil)
    puts "SYNC.perform: #{sync_type.inspect}, #{id.inspect}, #{user_id.inspect}"
    user = user_id.present? ? User.find(user_id) : User.find(id)
    syncer = Travis::VcsProxy::Syncer.new(user)
    case sync_type
    when SyncType::ORGANIZATION then syncer.sync_organization(Organization.find(id))
    when SyncType::REPOSITORY then syncer.sync_repository(Repository.find(id))
    when SyncType::USER then syncer.sync_user
    end
    puts "SYNC.done: #{sync_type.inspect}, #{id.inspect}, #{user_id.inspect}"
  end
end
