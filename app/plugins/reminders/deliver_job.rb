module Reminders
  # Delivers a due reminder and deletes it. Runs in the jobs process (no gateway),
  # sending over the REST API with the bot token. Idempotent: no-ops if the row is
  # gone, so no job cancellation needed.
  class DeliverJob < ApplicationJob
    include ActionView::Helpers::DateHelper # distance_of_time_in_words

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
      Discordrb::API::Channel.create_message(BotConfig.rest_token, channel_id, content(reminder))
    end

    # Resolved at delivery time: user choice or server's force_dm_reminders policy.
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
      "⏰ <@#{reminder.user_id}> you asked me #{ago} ago to remind you:\n> #{reminder.message}"
    end
  end
end
