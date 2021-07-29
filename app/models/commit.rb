# frozen_string_literal: true

class Commit < ApplicationRecord
  belongs_to :ref
  belongs_to :repository
  belongs_to :user

  validates_presence_of :ref_id, :repository_id, :user_id, :sha
end