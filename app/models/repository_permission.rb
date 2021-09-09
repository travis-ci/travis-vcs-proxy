# frozen_string_literal: true

class RepositoryPermission < ApplicationRecord
  belongs_to :repository
  belongs_to :user

  enum permission: %i[read write admin super]

  def owner?
    admin? || super?
  end
end
