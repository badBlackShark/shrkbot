# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class GamesController < Api::TwilightStruggle::BaseController
        def update
          tournament = referenced_tournament(params.dig(:game, :tournament_external_id), :tournament_external_id)
          result = Ops::TwilightStruggle::Games::Upsert.call(external_id: params[:external_id], tournament:)
          created = result.value&.previously_new_record?

          post_message(result.value) if result.success?

          render_upsert(result, created:)
        end

        def destroy
          game = ::TwilightStruggle::Game.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Games::Destroy.call(game:) if game
          head :no_content
        end

        private

        def post_message(game)
          report = ::TwilightStruggle::GameReport.from_payload(params[:game].to_unsafe_h)
          result = Ops::TwilightStruggle::Games::Post.call(game:, report:)
          return if result.success?

          Rails.logger.warn("[TwilightStruggle] game #{game.external_id} not posted: #{result.errors.to_sentence}")
        end
      end
    end
  end
end
