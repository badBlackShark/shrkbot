# frozen_string_literal: true

module Feeds
  class Twitch
    class Settings < ApplicationRecord
      LIVE_END_MODES = %w[mark_ended_with_vod mark_ended keep delete].freeze
      SWITCHED_AWAY_MODES = %w[summary delete].freeze
      MAX_CATEGORIES = 100
      NO_PING = 0

      self.table_name = "feed_twitch_settings"

      include ValidatesJsonList

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :show_viewers, inclusion: {in: [true, false]}
      validates(*Twitch::POST_TYPES.map(&:image_column), inclusion: {in: [true, false]})
      validates :live_end_mode, inclusion: {in: LIVE_END_MODES}
      validates :switched_away, inclusion: {in: SWITCHED_AWAY_MODES}
      validates :subscription_id, uniqueness: true
      validates_json_list(:categories, max: MAX_CATEGORIES) { |category| CategoryValue.valid?(category) }

      def role_id_for(event_type)
        override = role_override_for(event_type)
        return if override == NO_PING

        override || role_id
      end

      def role_override_for(event_type)
        public_send(Twitch.fetch_post_type(event_type).role_column)
      end

      def show_image?(event_type)
        public_send(Twitch.fetch_post_type(event_type).image_column)
      end

      def accepts_category?(category_id)
        categories.empty? || categories.any? { |category| category["id"] == category_id }
      end
    end
  end
end
