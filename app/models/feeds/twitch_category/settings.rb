# frozen_string_literal: true

module Feeds
  class TwitchCategory
    class Settings < ApplicationRecord
      MAX_LANGUAGES = 50
      MAX_EXCLUDED = 100
      LOGIN = /\A[a-z0-9_]{1,25}\z/

      self.table_name = "feed_twitch_category_settings"

      include ValidatesJsonList

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :min_viewers, numericality: {only_integer: true, greater_than_or_equal_to: 0}
      validates :show_viewers, :show_preview_frame, inclusion: {in: [true, false]}
      validates :live_end_mode, inclusion: {in: Twitch::Settings::LIVE_END_MODES}
      validates :switched_away, inclusion: {in: Twitch::Settings::SWITCHED_AWAY_MODES}
      validates :subscription_id, uniqueness: true
      validates_json_list(:languages, max: MAX_LANGUAGES) { |language| LANGUAGES.include?(language) }
      validates_json_list(:excluded_channels, max: MAX_EXCLUDED) { |login| login.is_a?(String) && login.match?(LOGIN) }

      def excluded_channels=(values)
        super(Array(values).filter_map { |value| normalise(value) }.uniq)
      end

      def role_id_for(_event_type)
        role_id
      end

      def show_image?(_event_type)
        show_preview_frame
      end

      def accepts_stream?(event)
        accepts_language?(event.language) && !excluded_channels.include?(event.login.to_s.downcase)
      end

      def meets_floor?(event)
        event.viewer_count.to_i >= min_viewers
      end

      private

      def accepts_language?(language)
        languages.empty? || languages.include?(language)
      end

      def normalise(value)
        Integrations::Twitch::ChannelReference.parse(value)
      rescue Integrations::InvalidReference
        value.to_s.strip.downcase.presence
      end
    end
  end
end
