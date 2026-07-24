# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Upsert < ApplicationOperation
        receives :external_id
        receives :tournament, optional: true

        def call
          record = ::TwilightStruggle::Game.find_or_initialize_by(external_id:)
          record.tournament = tournament || friendly_tournament

          if record.save
            ok(record)
          else
            failure(record.errors.full_messages)
          end
        end

        private

        def friendly_tournament
          ::TwilightStruggle::Tournament.find_by(friendly: true) || create_friendly_tournament
        end

        def create_friendly_tournament
          ::TwilightStruggle::Tournament.create!(friendly: true, name: I18n.t("twilight_struggle.friendly_tournament_name"))
        rescue ActiveRecord::RecordNotUnique
          ::TwilightStruggle::Tournament.find_by!(friendly: true)
        end
      end
    end
  end
end
