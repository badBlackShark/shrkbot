# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Destinations
      class Save < ApplicationOperation
        receives :destination, :active
        receives :discord_channel_id, optional: true
        receives :template_win, optional: true
        receives :template_tie, optional: true
        receives :template_video, optional: true
        receives :player_display, optional: true
        receives :post_delay_minutes, optional: true
        receives :archived, optional: true

        def call
          return invalid_post_delay unless post_delay_valid?

          destination.assign_attributes(settings)

          return failure(destination.errors.full_messages, value: destination) unless destination.save

          ok(destination)
        end

        private

        def settings
          {
            active: truthy?(active),
            discord_channel_id: discord_channel_id.presence,
            template_win: override(:win, template_win),
            template_tie: override(:tie, template_tie),
            template_video: override(:video, template_video),
            player_display: player_display.presence,
            post_delay_seconds:,
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

        def post_delay_valid?
          return true if post_delay_minutes.blank?

          post_delay_minutes.to_s.match?(/\A\d+\z/) && post_delay_minutes.to_i <= max_post_delay_minutes
        end

        def invalid_post_delay
          failure(
            I18n.t("operations.twilight_struggle.destinations.post_delay_invalid", max: max_post_delay_minutes),
            value: destination
          )
        end

        def max_post_delay_minutes
          ::TwilightStruggle::Destination::MAX_POST_DELAY.in_minutes.to_i
        end

        def post_delay_seconds
          return nil if post_delay_minutes.blank?

          post_delay_minutes.to_i.minutes.to_i
        end

        def archived_at
          return nil unless truthy?(archived)

          destination.archived_at || Time.current
        end
      end
    end
  end
end
