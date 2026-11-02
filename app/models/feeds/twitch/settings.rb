# frozen_string_literal: true

module Feeds
  module Twitch
    class Settings < ApplicationRecord
      ROLE_COLUMNS = {"Integrations::Twitch::StreamStarted" => :live_role_id}.freeze

      self.table_name = "feed_twitch_settings"

      belongs_to :subscription, class_name: "Feeds::Subscription"

      validates :show_viewers, inclusion: {in: [true, false]}
      validates :subscription_id, uniqueness: true

      def role_id_for(event_type)
        public_send(ROLE_COLUMNS.fetch(event_type))
      end
    end
  end
end
