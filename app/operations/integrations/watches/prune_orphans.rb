# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class PruneOrphans < ApplicationOperation
        def call
          return ok if ::Integrations::Watch.demand_sources.empty?

          ::Integrations::Watch.where.not(id: ::Integrations::Watch.referenced.select(:id)).find_each(&:destroy!)
          ok
        end
      end
    end
  end
end
