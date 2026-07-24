# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class GamesController < Api::TwilightStruggle::BaseController
        def update
          result_payload = ::TwilightStruggle::Result.new(result_attributes)
          return render json: {errors: result_payload.errors.full_messages}, status: :unprocessable_content if result_payload.invalid?

          tournament = referenced_tournament(game_params[:tournament_external_id], :tournament_external_id)

          render_upsert(Ops::TwilightStruggle::Games::Upsert.call(external_id: params[:external_id], tournament:))
        end

        def destroy
          game = ::TwilightStruggle::Game.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Games::Destroy.call(game:) if game
          head :no_content
        end

        private

        def game_params
          params.require(:game).permit(
            :tournament_external_id,
            :game_code,
            :game_date,
            :reported_at,
            :winning_side,
            :winning_turn,
            :winning_method,
            :usa_player,
            :usa_flag,
            :ussr_player,
            :ussr_flag,
            video_urls: []
          )
        end

        def result_attributes
          game_params.except(:tournament_external_id).to_h
        end
      end
    end
  end
end
