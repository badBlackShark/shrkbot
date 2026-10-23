# frozen_string_literal: true

module Ops
  module Integrations
    class Prune < ApplicationOperation
      RETENTION = 14.days

      def call
        cutoff = RETENTION.ago
        ::Integrations::Event.where(created_at: ...cutoff).delete_all
        ::Integrations::SeenItem.where(created_at: ...cutoff).delete_all
        ok
      end
    end
  end
end
