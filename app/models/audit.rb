# frozen_string_literal: true

class Audit < ApplicationRecord
  def self.create(user, log)
    Audit.new(owner_id: user.id, owner_type: 'User', updates: log).save
  end
end
