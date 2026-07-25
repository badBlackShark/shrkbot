# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Create < ApplicationOperation
        receives :server_configuration, :tournament

        def call
          destination = ::TwilightStruggle::Destination.new(server_configuration:, tournament:)

          return failure(destination.errors.full_messages) unless destination.save

          ok(destination)
        end
      end
    end
  end
end
