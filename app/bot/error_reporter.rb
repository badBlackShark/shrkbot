# frozen_string_literal: true

module Bot
  module ErrorReporter
    module_function

    def report(bot:, error:, source:)
      Rails.logger.error("[#{source}] #{error.class}: #{error.message}")
      Rails.error.report(
        error,
        handled: true,
        severity: :error,
        source: "bot",
        context: {tags: {origin: source}}
      )
      OwnerNotifier.report(bot:, error:, source:)
    end
  end
end
