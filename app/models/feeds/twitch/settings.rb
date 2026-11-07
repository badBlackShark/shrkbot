# frozen_string_literal: true

module Feeds
  module Twitch
    class Settings < ApplicationRecord
      ROLE_COLUMNS = {
        "Integrations::Twitch::StreamStarted" => :live_role_id,
        "Integrations::Twitch::HighlightPublished" => :highlights_role_id,
        "Integrations::Twitch::UploadPublished" => :uploads_role_id,
        "Integrations::Twitch::FeaturedClipPublished" => :featured_clips_role_id,
        "Integrations::Twitch::ClipCreated" => :clips_role_id
      }.freeze

      LIVE_END_MODES = %w[keep delete mark_ended mark_ended_with_vod].freeze

      self.table_name = "feed_twitch_settings"

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :show_viewers, inclusion: {in: [true, false]}
      validates :live_end_mode, inclusion: {in: LIVE_END_MODES}
      validates :subscription_id, uniqueness: true

      def role_id_for(event_type)
        public_send(ROLE_COLUMNS.fetch(event_type))
      end
    end
  end
end
