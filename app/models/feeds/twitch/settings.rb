# frozen_string_literal: true

module Feeds
  class Twitch
    class Settings < ApplicationRecord
      LIVE_END_MODES = %w[mark_ended_with_vod mark_ended keep delete].freeze
      SWITCHED_AWAY_MODES = %w[summary delete].freeze
      MAX_CATEGORIES = 100

      self.table_name = "feed_twitch_settings"

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :show_viewers, inclusion: {in: [true, false]}
      validates :live_end_mode, inclusion: {in: LIVE_END_MODES}
      validates :switched_away, inclusion: {in: SWITCHED_AWAY_MODES}
      validates :subscription_id, uniqueness: true
      validate :categories_shape
      validate :categories_count

      def role_id_for(event_type)
        public_send(Twitch.fetch_post_type(event_type).role_column)
      end

      def accepts_category?(category_id)
        categories.empty? || categories.any? { |category| category["id"] == category_id }
      end

      private

      def categories_shape
        return if categories.is_a?(Array) && categories.all? { |category| CategoryValue.valid?(category) }

        errors.add(:categories, :invalid)
      end

      def categories_count
        return unless categories.is_a?(Array) && categories.size > MAX_CATEGORIES

        errors.add(:categories, :too_long, count: MAX_CATEGORIES)
      end
    end
  end
end
