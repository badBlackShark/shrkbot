# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Subscribe < ApplicationOperation
        receives :destination

        def call
          destination.update!(active: true)
          ok(destination)
        end
      end
    end
  end
end
