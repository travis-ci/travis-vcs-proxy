# frozen_string_literal: true

class Ref < ApplicationRecord
  enum type: %i[branch tag]

  self.inheritance_column = nil

  belongs_to :repository

  has_many :commits, dependent: :destroy

  validates_presence_of :name, :type, :repository_id

  scope :branch, -> { where(type: types[:branch]) }
  scope :tag, -> { where(type: types[:tag]) }
end
