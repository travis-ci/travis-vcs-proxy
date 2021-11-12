# frozen_string_literal: true

class CommitSerializer < ApplicationSerializer
  attributes :id, :message, :sha, :committed_at

  attributes(:author) do |commit|
    {
      name: commit.user.name || commit.user.email,
      email: commit.user.email,
    }
  end
end
