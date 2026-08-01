# frozen_string_literal: true

module Bot
  module OwnerNotifier
    MAX_LENGTH = 1900

    module_function

    def report(bot:, error:, source:)
      return unless BotSetting.owner_error_dms?

      suppressed = ErrorThrottle.instance.admit([error.class.name, source])
      return if suppressed.nil?

      deliver(bot, format_message(error, source, suppressed))
    end

    def notify(bot:, message:)
      deliver(bot, message)
    end

    def deliver(bot, text)
      owner_id = Config.owner_id
      return if owner_id.to_s.strip.empty?

      bot.pm_channel(owner_id.to_i).send_message(text)
    rescue => e
      Rails.logger.error("[OwnerNotifier] could not DM owner: #{e.class}: #{e.message}")
    end

    def format_message(error, source, suppressed = 0)
      backtrace = Array(error.backtrace).first(8).join("\n")
      msg = <<~MSG
        ⚠️ **shrkbot error** (#{source})#{suppressed_note(suppressed)}
        **#{error.class}**: #{error.message}
        ```
        #{backtrace}
        ```
      MSG
      Discord::Truncate.call(msg, MAX_LENGTH)
    end

    def suppressed_note(count)
      return "" if count.zero?

      " — plus #{count} more in the previous #{ErrorThrottle::WINDOW.inspect}"
    end
  end
end
