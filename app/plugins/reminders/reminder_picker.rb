# frozen_string_literal: true

module Reminders
  module ReminderPicker
    def autocomplete
      choices = Reminders::Reminder.for_user(event.user.id).limit(25).map do |reminder|
        {name: choice_label(reminder), value: reminder.id}
      end
      event.respond(choices:)
    end

    private

    def picked_reminder
      Reminders::Reminder.find_by(id: event.options["reminder"], user_id: event.user.id)
    end

    def respond_missing
      event.respond(content: "⚠️ That reminder doesn't exist.", ephemeral: true)
    end

    def choice_label(reminder)
      "#{Bot::Discord::Truncate.call(reminder.message, 75)} (#{reminder.remind_at.strftime("%b %-d %H:%M %Z")})"
    end
  end
end
