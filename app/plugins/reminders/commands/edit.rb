# frozen_string_literal: true

module Reminders
  class Edit < Bot::BaseCommand
    include Reminders::ReminderPicker

    command_name :editreminder
    description "Change the text of one of your reminders."
    register_in :global
    options do |opts|
      opts.string("reminder", "Which reminder?", required: true, autocomplete: true)
      opts.string("message", "What should I remind you about instead?", required: true)
    end

    def execute
      reminder = picked_reminder
      return respond_missing unless reminder

      result = Ops::Reminders::Update.call(
        reminder:,
        message: event.options["message"]
      )

      if result.success?
        event.respond(content: "I'll remind you <t:#{reminder.remind_at.to_i}:R>:\n>>> #{reminder.message}", ephemeral: true)
      else
        event.respond(content: "⚠️ #{result.errors.first}", ephemeral: true)
      end
    end
  end
end
