class WebhookTriggerJob < ApplicationJob
  queue_as :default

  def perform(commit_id)
    commit = Commit.find(commit_id)

    TriggerWebhooks.new(commit).call
  end
end
