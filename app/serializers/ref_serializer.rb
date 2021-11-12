# frozen_string_literal: true

class RefSerializer < ApplicationSerializer
  attributes :id, :name

  attributes(:commit) do |ref|
    commit = ref.commits.order('committed_at DESC').first

    { sha: commit.sha } if commit.present?
  end
end
