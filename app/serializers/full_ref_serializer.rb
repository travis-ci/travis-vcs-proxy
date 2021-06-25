# frozen_string_literal: true

class FullRefSerializer < ApplicationSerializer
  attributes :id, :name

  attribute :type, -> (ref) { ref.type == Ref::BRANCH ? 'branch' : 'tag' }
end
