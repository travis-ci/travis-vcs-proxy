# frozen_string_literal: true

module V1
  class WebhooksController < ApplicationController
    def receive # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      puts 'WEBHOOK RECEIVED'
      puts "WEBHOOK params: #{params.inspect}"
      head(:unauthorized) && return unless organization = Organization.find_by(listener_token: params[:token])
      repository_name =  params[:change_root]&.match(%r{\A//([^/]+)/([^/]+)})
      repository_name = repository_name[1] if repository_name
      repository_name ||= params[:change_root]&.split('@')&.first
      puts "reponame: #{repository_name}"

      head(:ok) && return unless repository_name
      head(:ok) && return unless repository = organization.repositories.find_by(name: repository_name)

      puts "Repository: #{repository.inspect}"
      token = nil
      user = nil
      begin
        setting = RepositoryUserSetting.where(username: params[:username])
        setting.each do |s|
          p = RepositoryPermission.find(s.repository_permission_id)
          if p.repository_id == repository.id

            user = User.find(p.user_id)
            username = s.username
            token = s.value
            break
          end
        end
      rescue Exception => e
        puts "webhookERROR: #{e.message}"
        head(:ok) && return
      end

      head(:ok) && return unless token
      head(:internal_server_error) && return unless commit_info = repository.commit_info_from_webhook(params, params[:username], token)

      # TODO: Figure out if we should really ignore the hook if there is no user with the given email
      head(:ok) && return unless user

      ref = repository.refs.branch.find_by(name: commit_info[:ref])
      unless ref
        ref = repository.refs.branch.create(name: commit_info[:ref])
        ref&.save!
      end
      head(:unprocessable_entity) && return unless ref

      commit = ref.commits.find_by(sha: params[:sha])
      unless commit
        commit = ref.commits.create(sha: params[:sha], repository: repository, user: user, committed_at: Time.now, message: params[:message])
        commit&.save!
      end
      head(:unprocessable_entity) && return unless commit

      TriggerWebhooks.new(commit).call

      head :ok
    end
  end
end
