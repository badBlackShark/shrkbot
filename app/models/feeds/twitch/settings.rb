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
      SWITCHED_AWAY_MODES = %w[summary delete].freeze

      self.table_name = "feed_twitch_settings"

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :show_viewers, inclusion: {in: [true, false]}
      validates :live_end_mode, inclusion: {in: LIVE_END_MODES}
      validates :switched_away, inclusion: {in: SWITCHED_AWAY_MODES}
      validates :subscription_id, uniqueness: true
      validate :categories_shape

      def role_id_for(event_type)
        public_send(ROLE_COLUMNS.fetch(event_type))
      end

      def accepts_category?(category_id)
        categories.empty? || categories.any? { |category| category["id"] == category_id }
      end

      private

      def categories_shape
        return if categories.is_a?(Array) && categories.all? { |category| valid_category?(category) }

        errors.add(:categories, :invalid)
      end

      def valid_category?(category)
        category.is_a?(Hash) && category["id"].is_a?(String) && category["id"].present? && category["name"].is_a?(String)
      end
    end
  end
end
