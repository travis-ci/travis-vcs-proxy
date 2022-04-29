# frozen_string_literal: true

class RepositoryPermission < ApplicationRecord
  belongs_to :repository
  belongs_to :user

  enum permission: %i[read write admin super]

  has_one :setting, class_name: 'RepositoryUserSetting', foreign_key: :repository_permission_id, dependent: :delete

  def owner?
    admin? || super?
  end
end
