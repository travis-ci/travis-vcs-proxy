# frozen_string_literal: true

class TriggerWebhooks
  class WebhookError < StandardError; end

  def initialize(commit)
    @commit = commit
    @ref = commit.ref
    @repository = @ref.repository
    @server_provider = @repository.server_provider
  end

  def call
    @repository.webhooks.active.each do |webhook|
      begin
        process_webhook(webhook)
      rescue => e
        Rails.logger.error "An error happened while processing webhook id=#{webhook.id} name=#{webhook.name}: #{e.message}"
        Rails.logger.error "Partial backtrace:"
        Rails.logger.error(e.backtrace.first(20).join("\n"))
      end
    end
  end

  private

  def process_webhook(webhook)
    Rails.logger.info "Triggering webhook id=#{webhook.id} name=#{webhook.name}"
    uri = URI(webhook.url)

    res = Net::HTTP.post(
      uri,
      webhook_payload(webhook),
      'Content-Type' => 'application/json'
    )

    raise WebhookError.new("Request failed: code=#{res.code}, body=#{res.body}") unless res.is_a?(Net::HTTPSuccess)
  end

  def webhook_payload(webhook)
    JSON.dump(
      commit: {
        sha: @commit.sha,
        message: @commit.message,
        committed_at: @commit.committed_at,
      }
    )
  end
end