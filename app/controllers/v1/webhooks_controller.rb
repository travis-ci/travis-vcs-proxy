# frozen_string_literal: true

module V1
  class WebhooksController < ApplicationController
    def receive # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      puts 'WEBHOOK RECEIVED'
      puts "WEBHOOK params: #{params.inspect}"
      head(:unauthorized) && return unless repository = Repository.find_by(listener_token: params[:token])

      head(:internal_server_error) && return unless commit_info = repository.commit_info_from_webhook(params)

      # TODO: Figure out if we should really ignore the hook if there is no user with the given email
      head(:ok) && return unless user = repository.users.find_by(email: commit_info[:email])
      # TODO: Figure out if we should really ignore the hook if there is no repository with this name
      head(:ok) && return unless repository = Repository.find_by(name: commit_info[:repository_name])

      ref = repository.refs.branch.find_by(name: commit_info[:ref])
      unless ref
        ref = repository.refs.branch.create(name: commit_info[:ref])
        ref&.save!
      end
      head(:unprocessable_entity) && return unless ref

      commit = ref.commits.find_by(sha: params[:sha])
      unless commit
        commit = ref.commits.create(sha: params[:sha], repository: repository, user: user, committed_at: Time.now)
        commit&.save!
      end
      head(:unprocessable_entity) && return unless commit

      TriggerWebhooks.new(commit).call

      head :ok
    end
  end
end
