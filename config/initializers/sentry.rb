# frozen_string_literal: true

require_relative "../../lib/sentry_http_scrubber"

Sentry.init do |config|
  config.enabled_environments = %w[production development]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.before_breadcrumb = SentryHttpScrubber.method(:breadcrumb)
  config.before_send_transaction = SentryHttpScrubber.method(:transaction)
  config.traces_sample_rate = 1.0
  config.data_collection.http_headers.request.terms += ["referer"]
  config.rails.register_error_subscriber = true
  config.enabled_patches += [:solid_queue_recurring] if Rails.env.production?
  config.rails.solid_queue_exclude_recurring_tasks = [/\A(?!integrations_stranded_event_dispatch\z)/]
  config.cron.default_checkin_margin = 5
end
