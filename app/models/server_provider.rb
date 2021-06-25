# frozen_string_literal: true

class ServerProvider < ApplicationRecord
  has_many :server_provider_permissions, dependent: :destroy
  has_many :users, through: :server_provider_permissions

  has_many :repositories, dependent: :destroy

  validates_presence_of :name, :url, :type
end
