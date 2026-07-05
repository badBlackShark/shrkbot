# frozen_string_literal: true

module Reminders
  class DeliverJob < ApplicationJob
    include ActionView::Helpers::DateHelper

    queue_as :default

    def perform(reminder_id)
      reminder = Reminders::Reminder.find_by(id: reminder_id)
      return unless reminder

      deliver(reminder)
      reminder.destroy!
    end

    private

    def deliver(reminder)
      channel_id = deliver_via_dm?(reminder) ? dm_channel_id(reminder.user_id) : reminder.channel_id
      rendered = message(reminder)
      Discordrb::API::Channel.create_message(
        BotConfig.rest_token,
        channel_id,
        nil,
        false,
        nil,
        nil,
        nil,
        nil,
        nil,
        rendered[:components],
        rendered[:flags]
      )
    end

    def message(reminder)
      Discord::Components.container([Discord::Components.text(content(reminder))])
    end

    def deliver_via_dm?(reminder)
      return true if reminder.deliver_via_dm
      return false unless reminder.server_id

      ServerConfiguration.find_by(discord_id: reminder.server_id)&.force_dm_reminders || false
    end

    def dm_channel_id(user_id)
      JSON.parse(Discordrb::API::User.create_pm(BotConfig.rest_token, user_id))["id"]
    end

    def content(reminder)
      ago = distance_of_time_in_words(reminder.created_at, reminder.remind_at)
      "<@#{reminder.user_id}>, you asked me #{ago} ago to remind you:\n> #{reminder.message}"
    end
  end
end
