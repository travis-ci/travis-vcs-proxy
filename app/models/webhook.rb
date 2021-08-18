# frozen_string_literal: true

class Webhook < ApplicationRecord
  belongs_to :repository

  validates_presence_of :repository_id, :name, :url

  scope :active, -> { where(active: true) }
  validates :url, url: { schemes: %w(https http) }
end
