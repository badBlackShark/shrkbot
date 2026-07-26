# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Destroy < ApplicationOperation
        receives :destination

        def call
          destination.destroy! if destination.persisted?
          ok(destination)
        end
      end
    end
  end
end
