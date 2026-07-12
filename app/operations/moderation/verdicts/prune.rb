# frozen_string_literal: true

module Ops
  module Moderation
    module Verdicts
      class Prune < ApplicationOperation
        def call
          ::Moderation::VerdictRecord.where(created_at: ...30.days.ago).delete_all
          ok
        end
      end
    end
  end
end
