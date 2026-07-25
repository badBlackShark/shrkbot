# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Configure < ApplicationOperation
        receives :tournament
        receives :discord_channel_id, optional: true
        receives :template_win, optional: true
        receives :template_tie, optional: true
        receives :template_video, optional: true
        receives :ping_players, optional: true
        receives :archived, optional: true

        def call
          tournament.assign_attributes(
            discord_channel_id: discord_channel_id.presence,
            template_win: template_win.presence,
            template_tie: template_tie.presence,
            template_video: template_video.presence,
            ping_players: ping_preference,
            archived_at: archived_at
          )
          return failure(tournament.errors.full_messages) unless tournament.save

          ok(tournament)
        end

        private

        def ping_preference
          return nil if ping_players.blank?

          truthy?(ping_players)
        end

        def archived_at
          return nil unless truthy?(archived)

          tournament.archived_at || Time.current
        end
      end
    end
  end
end
