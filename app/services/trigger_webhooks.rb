# frozen_string_literal: true

require 'securerandom'

class TriggerWebhooks
  class WebhookError < StandardError; end

  def initialize(commit)
    @commit = commit
    @ref = commit.ref
    @repository = @ref.repository
    @user = commit.user
    @owner_id = @repository.owner_id
    @owner_type = @repository.owner_type
  end

  def call
    @repository.webhooks.active.each do |webhook|
      process_webhook(webhook)
    rescue StandardError => e
      Rails.logger.error "An error happened while processing webhook id=#{webhook.id} name=#{webhook.name}: #{e.message}"
      Rails.logger.error 'Partial backtrace:'
      Rails.logger.error(e.backtrace.first(20).join("\n"))
    end
  end

  private

  def process_webhook(webhook)
    Rails.logger.info "Triggering webhook id=#{webhook.id} name=#{webhook.name}"
    uri = URI(webhook.url)

    res = Net::HTTP.post(
      uri,
      webhook_payload(webhook),
      'Content-Type' => 'application/json',
      'X-Travisproxy-Event-Id' => SecureRandom.uuid,
      'X-Request-Id' => SecureRandom.uuid
    )

    raise WebhookError, "Request failed: code=#{res.code}, body=#{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end

  def webhook_payload(webhook)
    JSON.dump(
      branch_name: @ref&.name || 'main',
      sender_id: @commit.user_id.to_s,
      new_revision: "#{@ref.name}@#{@commit.sha}",
      sender_login: @user.email,
      server_type: server_type,
      owner_vcs_id: @repository.owner_id.to_s,
      sender_vcs_id: @commit.user_id.to_s,
      repository: {
        id: @repository.id.to_s,
        name: @repository.name,
        full_name: @repository.name,
        slug: @repository.url,
        is_private: true,

      },
      commits: [
        {
          id: @commit.id.to_s,
          sha: "#{@ref.name}@#{@commit.sha}",
          revision: "#{@ref.name}@#{@commit.sha}",
          message: @commit.message || '',
          committed_at: @commit.committed_at,
          commiter_name: @user.name || '',
          commiter_email: @user.email || '',
        },
      ]
    )
  end

  def server_type
    @repository.server_type
  end
end
