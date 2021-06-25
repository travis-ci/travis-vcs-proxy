# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class Repository
        def initialize(repository)
          @repository = repository
        end

        def sync
        end
      end
    end
  end
end
