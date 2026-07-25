# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Release < ApplicationOperation
        receives :tournament

        def call
          tournament.update!(server_configuration: nil, discord_channel_id: nil)
          ok(tournament)
        end
      end
    end
  end
end
