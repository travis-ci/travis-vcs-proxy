# frozen_string_literal: true

module V1
  class WebhooksController < ApplicationController
    def receive # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      head(:unauthorized) && return unless server_provider = ServerProvider.find_by(listener_token: params[:token])

      head(:internal_server_error) && return unless commit_info = server_provider.commit_info_from_webhook(params)

      # TODO: Figure out if we should really ignore the hook if there is no user with the given email
      head(:ok) && return unless user = server_provider.users.find_by(email: commit_info[:email])
      # TODO: Figure out if we should really ignore the hook if there is no repository with this name
      head(:ok) && return unless repository = server_provider.repositories.find_by(name: commit_info[:repository_name])

      ref = repository.refs.branch.find_by(name: commit_info[:ref]) || repository.refs.branch.create(name: commit_info[:ref])
      head(:unprocessable_entity) && return unless ref

      commit = ref.commits.find_by(sha: params[:sha]) ||
        ref.commits.create(
          sha: params[:sha],
          repository: repository,
          user: user,
          committed_at: params[:timestamp] ? Time.at(params[:timestamp]) : Time.now,
          message: params[:message] || ""
        )
      head(:unprocessable_entity) && return unless commit

      TriggerWebhooks.new(commit).call

      head :ok
    end
  end
end
