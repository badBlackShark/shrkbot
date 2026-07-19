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
      message_id = Bot::Discord::Components.create_message(channel_id:, content: subject(reminder), allowed_mentions: {parse: [], users: [reminder.user_id]})
      Bot::Discord::Components.convert_to_v2(channel_id, message_id, message(reminder))
    end

    def subject(reminder)
      "Reminder: #{reminder.message} <@#{reminder.user_id}>"
    end

    def message(reminder)
      Bot::Discord::Components.container([Bot::Discord::Components.text(content(reminder))])
    end

    def deliver_via_dm?(reminder)
      return true if reminder.deliver_via_dm
      return false unless reminder.server_id

      ServerConfiguration.find_by(discord_id: reminder.server_id)&.force_dm_reminders || false
    end

    def dm_channel_id(user_id)
      response_id(Discordrb::API::User.create_pm(Bot::Config.rest_token, user_id))
    end

    def response_id(response)
      JSON.parse(response)["id"]
    end

    def content(reminder)
      ago = distance_of_time_in_words(reminder.created_at, reminder.remind_at)
      "<@#{reminder.user_id}>, you asked me #{ago} ago to remind you:\n> #{reminder.message}"
    end
  end
end
