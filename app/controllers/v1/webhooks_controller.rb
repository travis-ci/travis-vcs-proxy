# frozen_string_literal: true

module V1
  class WebhooksController < ApplicationController
    def receive # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      puts 'WEBHOOK RECEIVED'
      puts "WEBHOOK params: #{params.inspect}"
      organization = Organization.find_by(listener_token: params[:token])
      repository = nil
      if organization
        repository_name = params[:ref]&.match(%r{\A//([^/]+)/([^/]+)}) unless params[:change_root]
        repository_name = repository_name[1] if repository_name
        unless repository_name
          repository_path = params[:change_root]&.split('/')
          repository_name = repository_path.last if repository_path.length > 1
        end
        repository_name ||= params[:change_root]&.split('@')&.first
        puts "reponame: #{repository_name}"

        params[:change_root] = params[:ref] unless params[:change_root]

        head(:not_found) && return unless repository_name
        head(:not_found) && return unless repository = organization.repositories.find_by(name: repository_name)
      else
        params[:change_root] = params[:ref] unless params[:change_root]
        head(:unauthorized) && return unless repository = Repository.find_by(listener_token: params[:token])
      end

      puts "Repository: #{repository.inspect}"
      token = nil
      user = nil
      begin
        setting = RepositoryUserSetting.where(username: params[:username])
        setting.each do |s|
          p = RepositoryPermission.find(s.repository_permission_id)
          next unless p.repository_id == repository.id

          user = User.find(p.user_id)
          token = repository.decrypted_token(s.value)
          break
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
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
