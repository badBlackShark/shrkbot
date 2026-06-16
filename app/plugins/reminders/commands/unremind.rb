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
      # Array so same-text reminders don't collapse; absolute time keeps labels distinct.
      choices = Reminders::Reminder.for_user(event.user.id).limit(25).map do |reminder|
        {name: choice_label(reminder), value: reminder.id}
      end
      event.respond(choices: choices)
    end

    private

    def choice_label(reminder)
      # Discord choice names can't use dynamic <t:> markup, so use plain timestamp.
      "#{reminder.message.truncate(75)} (#{reminder.remind_at.strftime("%b %-d %H:%M %Z")})"
    end
  end
end
