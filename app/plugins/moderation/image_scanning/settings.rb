# frozen_string_literal: true

module Moderation
  module ImageScanning
    class Settings < ApplicationRecord
      include Moderation::Punishable
      include Moderation::SubPluginSettings

      self.table_name = "image_scanning_settings"

      MAX_KEYWORDS = 200

      belongs_to :server_configuration

      string_enum :sensitivity, %w[relaxed standard strict]
      string_enum :action, %w[none delete], prefix: true
      string_enum :confirmed_punishment, %w[none timeout kick ban], prefix: true
      validates :confirmed_timeout_seconds,
        numericality: {only_integer: true, greater_than_or_equal_to: 60, less_than_or_equal_to: 2_419_200}
      validates :custom_keyword_min_hits,
        numericality: {only_integer: true, greater_than_or_equal_to: 1}
      validate :custom_keywords_within_limit
      validate :custom_keywords_not_blank
      validate :min_hits_within_keyword_count

      def self.active_for(discord_id)
        active_group_settings(discord_id, :image_scanning) { |config| config.image_scanning_settings }
      end

      private

      def custom_keywords_within_limit
        return if custom_keywords.size <= MAX_KEYWORDS

        errors.add(:custom_keywords, "can have at most #{MAX_KEYWORDS} entries")
      end

      def custom_keywords_not_blank
        return if custom_keywords.all? { |keyword| keyword.to_s.strip.present? }

        errors.add(:custom_keywords, "can't contain blank entries")
      end

      def min_hits_within_keyword_count
        return if custom_keywords.empty?
        return if custom_keyword_min_hits <= custom_keywords.size

        errors.add(:custom_keyword_min_hits, "can't exceed the number of keywords")
      end
    end
  end
end
