# frozen_string_literal: true

class ServerProviderSerializer < ApplicationSerializer
  attributes :id, :name, :url, :type

  attribute(:repositories) { |server| server.repositories.map(&:id) }
end
