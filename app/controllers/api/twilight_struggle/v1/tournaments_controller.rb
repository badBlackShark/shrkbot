# frozen_string_literal: true

module Api
  module TwilightStruggle
    module V1
      class TournamentsController < Api::TwilightStruggle::BaseController
        def update
          parent = referenced_tournament(params.dig(:tournament, :parent_external_id), :parent_external_id)

          result = Ops::TwilightStruggle::Tournaments::Upsert.call(
            external_id: params[:external_id],
            name: params.dig(:tournament, :name),
            parent:,
            status: params.dig(:tournament, :status),
            admins: params.dig(:tournament, :admins)
          )
          render_upsert(result)
        end

        def destroy
          tournament = ::TwilightStruggle::Tournament.find_by(external_id: params[:external_id])
          Ops::TwilightStruggle::Tournaments::Destroy.call(tournament:) if tournament
          head :no_content
        end
      end
    end
  end
end
