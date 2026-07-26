# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Save < ApplicationOperation
        receives :destination
        receives :discord_channel_id, optional: true
        receives :template_win, optional: true
        receives :template_tie, optional: true
        receives :template_video, optional: true
        receives :ping_players, optional: true
        receives :archived, optional: true

        def call
          destination.assign_attributes(settings)

          return failure(destination.errors.full_messages, value: destination) unless destination.save

          ok(destination)
        end

        private

        def settings
          {
            discord_channel_id: discord_channel_id.presence,
            template_win: override(:win, template_win),
            template_tie: override(:tie, template_tie),
            template_video: override(:video, template_video),
            ping_players: ping_preference,
            archived_at: archived_at
          }
        end

        # The form arrives pre-filled with whatever the destination would inherit,
        # so text that came back untouched is not an override — storing it would
        # freeze a copy and stop it tracking the tournament above.
        def override(kind, submitted)
          submitted = submitted.presence
          return nil if submitted == inherited.public_send(:"template_#{kind}")

          submitted
        end

        def inherited
          @inherited ||= ::TwilightStruggle::EffectiveConfig.new(
            destination.tournament.parent,
            destination.server_configuration
          )
        end

        def ping_preference
          return nil if ping_players.blank?

          truthy?(ping_players)
        end

        def archived_at
          return nil unless truthy?(archived)

          destination.archived_at || Time.current
        end
      end
    end
  end
end
