# frozen_string_literal: true

module OwnerNotifier
  MAX_LENGTH = 1900

  module_function

  def report(bot:, error:, source:)
    deliver(bot, format_message(error, source)) if BotSetting.owner_error_dms?
  end

  def notify(bot:, message:)
    deliver(bot, message)
  end

  def deliver(bot, text)
    owner_id = BotConfig.owner_id
    return if owner_id.to_s.strip.empty?

    bot.pm_channel(owner_id.to_i).send_message(text)
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
    Discord::Truncate.call(msg, MAX_LENGTH)
  end
end
