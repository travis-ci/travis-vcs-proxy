# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class ServerProvider
        def initialize(server_provider)
          @server_provider = server_provider
        end

        def sync
          ActiveRecord::Base.transaction do
            @server_provider.users.each do |user|
              connection = Travis::VcsProxy::P4Connection.new(@server_provider, user, user.server_provider_permission(@server_provider.id).setting.token)
              repos = connection.repositories.map do |repository|
                repo = @server_provider.repositories.first_or_initialize(name: repository[:name])
                unless repo.persisted?
                  repo.url = 'STUB'
                  repo.save!
                end

                repo
              end

              repos.each do |repo|
                connection.branches(repo.name).each do |branch|
                  repo.refs.find_or_create_by!(type: Ref::BRANCH, name: branch[:name].sub(/\A\/\/#{Regexp.escape(repo.name)}\//, ''))
                end
              end
            end
          end
        end
      end
    end
  end
end
