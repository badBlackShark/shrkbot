# frozen_string_literal: true

module Moderation
  module SpamProtection
    class Settings < ApplicationRecord
      include Moderation::Punishable
      include Moderation::SubPluginSettings

      self.table_name = "spam_protection_settings"

      ACTIONS = %w[purge notify_only].freeze

      belongs_to :server_configuration

      validates :channel_threshold,
        numericality: {only_integer: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 500}
      validates :window_seconds,
        numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 60}
      validates :similarity,
        numericality: {greater_than_or_equal_to: 0.75, less_than_or_equal_to: 1.0}
      validates :action, inclusion: {in: ACTIONS}

      def self.active_for(discord_id)
        active_group_settings(discord_id, :spam_protection) { |config| config.spam_protection_settings }
      end
    end
  end
end
