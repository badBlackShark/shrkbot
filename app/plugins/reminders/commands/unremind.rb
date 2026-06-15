module Reminders
  # /unremind <reminder> — cancel a reminder, picked from an autocomplete list of
  # the user's own active reminders (the option value is the reminder id).
  class Unremind < BaseCommand
    command_name :unremind
    description "Cancel one of your reminders."
    register_in :global
    options do |opts|
      opts.string("reminder", "Which reminder?", required: true, autocomplete: true)
    end

    def execute
      result = DeleteReminder.call(reminder_id: event.options["reminder"], user_id: event.user.id)
      content = result.success? ? "🗑️ Reminder cancelled." : "⚠️ #{result.errors.first}"
      event.respond(content: content, ephemeral: true)
    end

    def autocomplete
      choices = Reminders::Reminder.for_user(event.user.id).limit(25).to_h do |reminder|
        [reminder.message.truncate(90), reminder.id]
      end
      event.respond(choices: choices)
    end
  end
end
