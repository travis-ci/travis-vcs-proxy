# frozen_string_literal: true

class CommitSerializer < ApplicationSerializer
  attributes :id, :message, :committed_at

  attributes(:sha) { |commit| "#{commit.ref.name}@#{commit.sha}" }

  attributes(:author) do |commit|
    {
      name: commit.user.name || commit.user.email,
      email: commit.user.email,
    }
  end
end
