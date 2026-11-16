# frozen_string_literal: true

Sentry.init do |config|
  config.enabled_environments = %w[production development]
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sample_rate = 1.0
  config.rails.register_error_subscriber = true
  config.enabled_patches += [:solid_queue_recurring]
  config.rails.solid_queue_exclude_recurring_tasks = [/\A(?!integrations_stranded_event_dispatch\z)/]
end
