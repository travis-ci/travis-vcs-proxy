# frozen_string_literal: true

class OrganizationPermission < ApplicationRecord
  belongs_to :organization
  belongs_to :user

#  has_one :setting, class_name: 'OrganizationUserSetting', foreign_key: :organization_user_id, dependent: :delete

  enum permission: %i[owner member]
end
