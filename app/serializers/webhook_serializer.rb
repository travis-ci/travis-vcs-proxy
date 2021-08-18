# frozen_string_literal: true

class WebhookSerializer < ApplicationSerializer
  attributes :id, :name, :url, :active, :insecure_ssl, :created_at
end
