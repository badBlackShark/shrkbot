# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Claim < ApplicationOperation
        receives :tournament, :server_configuration

        def call
          tournament.lock!
          return failure(I18n.t("operations.twilight_struggle.tournaments.already_claimed")) if tournament.claimed?

          tournament.update!(server_configuration:)
          ok(tournament)
        end
      end
    end
  end
end
