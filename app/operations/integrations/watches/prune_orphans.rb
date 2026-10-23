# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class PruneOrphans < ApplicationOperation
        def call
          ::Integrations::Watch.where.not(id: ::Integrations::Watch.referenced.select(:id)).find_each(&:destroy!)
          ok
        end
      end
    end
  end
end
