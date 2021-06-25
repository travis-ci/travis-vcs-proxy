# frozen_string_literal: true

class Ref < ApplicationRecord
  BRANCH = 1
  TAG = 2

  self.inheritance_column = nil

  belongs_to :repository

  validates_presence_of :name, :type, :repository_id

  scope :branch, -> { where(type: BRANCH) }
  scope :tag, -> { where(type: TAG) }
end
