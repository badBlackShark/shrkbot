# frozen_string_literal: true

module Reminders
  class Unremind < Bot::BaseCommand
    include Reminders::ReminderPicker

    command_name :unremind
    description "Cancel one of your reminders."
    register_in :global
    options do |opts|
      opts.string("reminder", "Which reminder?", required: true, autocomplete: true)
    end

    def execute
      reminder = picked_reminder
      return respond_missing unless reminder

      Ops::Reminders::Delete.call(reminder:)
      event.respond(content: "Reminder canceled.", ephemeral: true)
    end
  end
end
