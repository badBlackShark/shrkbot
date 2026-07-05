# frozen_string_literal: true

module Reminders
  class List < BaseCommand
    command_name :reminders
    description "List your active reminders."
    register_in :global

    def execute
      reminders = Reminders::Reminder.for_user(event.user.id)

      if reminders.empty?
        event.respond(content: "You have no active reminders.", ephemeral: true)
      else
        lines = reminders.map { |r| "• <t:#{r.remind_at.to_i}:R> - #{Discord::Truncate.call(r.message, 80)}" }
        event.respond(content: lines.join("\n"), ephemeral: true)
      end
    end
  end
end
