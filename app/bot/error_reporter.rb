# frozen_string_literal: true

module Bot
  module ErrorReporter
    module_function

    def report(bot:, error:, source:)
      track(error:, source:)
      OwnerNotifier.report(bot:, error:, source:)
    end

    def track(error:, source:)
      Rails.logger.error("[#{source}] #{error.class}: #{error.message}")
      Rails.error.report(
        error,
        handled: true,
        severity: :error,
        source: "bot",
        context: {tags: {origin: source}}
      )
    end
  end
end
