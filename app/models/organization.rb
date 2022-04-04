# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :organization_permissions, dependent: :destroy
  has_many :users, through: :organization_permissions

  has_many :repositories, foreign_key: 'owner_id'

  validates_presence_of :name

  before_save :generate_listener_token

  has_settings(persistent: true) do |s|
    s.key :generic
  end

  def generate_listener_token
    return if listener_token.present?

    self.listener_token = SecureRandom.hex(40)
  end
end
