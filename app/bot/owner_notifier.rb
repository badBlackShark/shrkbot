# DMs the bot owner exception details when a command/event raises. Gated by the
# runtime Setting.owner_error_dms? flag (off by default). Self-guarding: a
# failure here must never mask the original error.
module OwnerNotifier
  MAX_LENGTH = 1900 # Discord message cap is 2000; leave headroom.

  module_function

  def report(bot:, error:, source:)
    return unless Setting.owner_error_dms?

    owner_id = BotConfig.owner_id
    return if owner_id.to_s.strip.empty?

    bot.pm_channel(owner_id.to_i).send_message(format_message(error, source))
  rescue => e
    Rails.logger.error("[OwnerNotifier] could not DM owner: #{e.class}: #{e.message}")
  end

  def format_message(error, source)
    backtrace = Array(error.backtrace).first(8).join("\n")
    msg = <<~MSG
      ⚠️ **shrkbot error** (#{source})
      **#{error.class}**: #{error.message}
      ```
      #{backtrace}
      ```
    MSG
    (msg.length > MAX_LENGTH) ? "#{msg[0, MAX_LENGTH]}…" : msg
  end
end
