# frozen_string_literal: true

class RepositorySerializer < ApplicationSerializer
  attributes :id, :name, :last_synced_at
end
