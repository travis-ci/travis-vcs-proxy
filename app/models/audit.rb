# frozen_string_literal: true

class Audit < ApplicationRecord

  def self.create(user,log)
    puts "NEW AUDIT!"
    Audit.new(owner_id: user.id, owner_type: 'User', updates: log).save
  end
end
