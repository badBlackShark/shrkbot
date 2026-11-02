# frozen_string_literal: true

module RecordsWatchFailures
  private

  def new_bug?(watch, error)
    !error.is_a?(::Integrations::Error) && new_error?(watch, error)
  end

  def new_error?(watch, error)
    !watch.last_error.to_s.start_with?("#{error.class}:")
  end

  def record_failure(watch, error)
    Rails.logger.warn("Integrations: #{watch.watcher} #{watch.external_id} failed: #{error.class}: #{error.message}")
    current = ::Integrations::Watch.find_by(id: watch.id)
    return if current.nil?

    Rails.logger.error(error.full_message(highlight: false)) unless error.is_a?(::Integrations::Error)

    Ops::Integrations::Watches::RecordFailure.call(watch: current, error:)
    current
  end
end
