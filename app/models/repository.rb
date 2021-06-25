# frozen_string_literal: true

class Repository < ApplicationRecord
  belongs_to :server_provider

  validates_presence_of :name, :url, :server_provider_id

  has_many :refs, dependent: :destroy
  has_many :permissions, class_name: 'RepositoryPermission', dependent: :delete_all

  def branches
    refs.branch
  end

  def tags
    refs.tag
  end
end
