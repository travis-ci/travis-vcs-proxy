# frozen_string_literal: true

class ServerProvider < ApplicationRecord
  has_many :server_provider_permissions, dependent: :destroy
  has_many :users, through: :server_provider_permissions

  has_many :repositories, dependent: :destroy

  validates_presence_of :name, :url, :type

  has_settings(persistent: true) do |s|
    s.key :generic
  end

  before_save :generate_listener_token

  private

  def generate_listener_token
    return if listener_token.present?

    self.listener_token = SecureRandom.hex(40)
  end
end
