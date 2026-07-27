# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Unsubscribe < ApplicationOperation
        receives :destination

        def call
          destination.update!(active: false) if destination.persisted?
          ok(destination)
        end
      end
    end
  end
end
