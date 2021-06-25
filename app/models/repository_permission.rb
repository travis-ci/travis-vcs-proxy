# frozen_string_literal: true

class RepositoryPermission < ApplicationRecord
  belongs_to :repository
  belongs_to :user

  READ = 1
  WRITE = 2
  ADMIN = 3
  SUPER = 4
end
