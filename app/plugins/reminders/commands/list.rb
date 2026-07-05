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
        event.respond(components: message(reminders)[:components], ephemeral: true, has_components: true)
      end
    end

    private

    def message(reminders)
      lines = reminders.map { |r| "- <t:#{r.remind_at.to_i}:R> - #{Discord::Truncate.call(r.message, 80)}" }
      Discord::Components.container(
        [Discord::Components.text("### Your reminders\n#{lines.join("\n")}")]
      )
    end
  end
end
