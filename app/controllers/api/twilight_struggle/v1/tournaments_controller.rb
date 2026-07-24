# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class TournamentsController < Api::TwilightStruggle::BaseController
        def update
          parent = referenced_tournament(tournament_params[:parent_external_id], :parent_external_id)

          result = Ops::TwilightStruggle::Tournaments::Upsert.call(
            external_id: params[:external_id],
            name: tournament_params[:name],
            parent:,
            status: tournament_params[:status]
          )
          render_upsert(result)
        end

        def destroy
          tournament = ::TwilightStruggle::Tournament.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Tournaments::Destroy.call(tournament:) if tournament
          head :no_content
        end

        private

        def tournament_params
          params.require(:tournament).permit(:name, :parent_external_id, :status)
        end
      end
    end
  end
end
