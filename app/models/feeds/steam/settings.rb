# frozen_string_literal: true

module Feeds
  module Steam
    class Settings < ApplicationRecord
      BODY_LENGTHS = %w[preview full].freeze

      self.table_name = "feed_steam_settings"

      belongs_to :subscription, class_name: "Feeds::Subscription"

      normalizes :languages, with: ->(languages) { languages.compact_blank.uniq }

      validates :body_length, inclusion: {in: BODY_LENGTHS}
      validates :subscription_id, uniqueness: true
      validate :languages_supported

      def accepts_language?(language)
        languages.empty? || language.nil? || languages.include?(language)
      end

      private

      def languages_supported
        errors.add(:languages, :inclusion) unless (languages - Integrations::Language::CODES).empty?
      end
    end
  end
end
