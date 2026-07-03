# frozen_string_literal: true

module Ops
  module Roles
    module Sets
      class Update < ApplicationOperation
        receives :role_set, :name, :selection_mode, :channel_override

        def call
          role_set.update!(name:, selection_mode:, channel_override:)
          ok(role_set)
        end
      end
    end
  end
end
