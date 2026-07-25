# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class GamesController < Api::TwilightStruggle::BaseController
        def update
          tournament = referenced_tournament(params.dig(:game, :tournament_external_id), :tournament_external_id)

          render_upsert(
            Ops::TwilightStruggle::Games::Upsert.call(
              external_id: params[:external_id],
              tournament:,
              payload: params[:game].to_unsafe_h.to_h
            )
          )
        end

        def destroy
          game = ::TwilightStruggle::Game.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Games::Destroy.call(game:) if game
          head :no_content
        end
      end
    end
  end
end
