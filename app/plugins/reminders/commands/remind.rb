module Reminders
  class Remind < BaseCommand
    command_name :remind
    description "Set a reminder to be sent to you after a delay (e.g. 1d2h30m)."
    register_in :global
    options do |opts|
      opts.string("duration", "When? e.g. 1d2h30m", required: true)
      opts.string("message", "What should I remind you about?", required: true)
      opts.string("deliver", "Where to deliver it (default: here)", required: false,
        choices: {"Here" => "here", "DM" => "dm"})
    end

    def execute
      result = CreateReminder.call(
        user_id: event.user.id,
        channel_id: event.channel_id,
        server_id: event.server_id,
        message: event.options["message"],
        duration: event.options["duration"],
        deliver_via_dm: event.options["deliver"] == "dm"
      )

      if result.success?
        event.respond(content: "👍 I'll remind you <t:#{result.value.remind_at.to_i}:R>.", ephemeral: true)
      else
        event.respond(content: "⚠️ #{result.errors.first}", ephemeral: true)
      end
    end
  end
end
