# frozen_string_literal: true

module Reminders
  class Unremind < BaseCommand
    command_name :unremind
    description "Cancel one of your reminders."
    register_in :global
    options do |opts|
      opts.string("reminder", "Which reminder?", required: true, autocomplete: true)
    end

    def execute
      reminder = Reminders::Reminder.find_by(id: event.options["reminder"], user_id: event.user.id)
      return event.respond(content: "⚠️ That reminder doesn't exist.", ephemeral: true) unless reminder

      Ops::Reminders::Delete.call(reminder: reminder)
      event.respond(content: "🗑️ Reminder cancelled.", ephemeral: true)
    end

    def autocomplete
      choices = Reminders::Reminder.for_user(event.user.id).limit(25).map do |reminder|
        {name: choice_label(reminder), value: reminder.id}
      end
      event.respond(choices: choices)
    end

    private

    def choice_label(reminder)
      "#{Discord::Truncate.call(reminder.message, 75)} (#{reminder.remind_at.strftime("%b %-d %H:%M %Z")})"
    end
  end
end
