# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class GamesController < Api::TwilightStruggle::BaseController
        def update
          tournament = referenced_tournament(params.dig(:game, :tournament_external_id), :tournament_external_id)
          result = Ops::TwilightStruggle::Games::Upsert.call(external_id: params[:external_id], tournament:)

          enqueue_post(result.value) if result.success?

          render_upsert(result)
        end

        def destroy
          game = ::TwilightStruggle::Game.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Games::Destroy.call(game:) if game
          head :no_content
        end

        private

        def enqueue_post(game)
          ::TwilightStruggle::PostJob.perform_later(game, params[:game].to_unsafe_h.to_h)
        end
      end
    end
  end
end
