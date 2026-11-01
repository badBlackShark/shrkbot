# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class Refresh < ApplicationOperation
        receives :watches, :targets

        def call
          by_external_id = targets.index_by(&:external_id)
          watches.each do |watch|
            target = by_external_id[watch.external_id]
            watch.update!(name: target.name, image_url: target.image_url) if target
          end
          ok
        end
      end
    end
  end
end
