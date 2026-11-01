# frozen_string_literal: true

module Integrations
  class RefreshWatchesJob < ApplicationJob
    queue_as :default

    def perform(watcher)
      watches = Watch.referenced.where(watcher:).to_a
      return if watches.empty?

      targets = watcher.constantize.refresh(watches.map(&:external_id))
      Ops::Integrations::Watches::Refresh.call(watches:, targets:)
    rescue Error => error
      Rails.logger.warn("Integrations: refreshing #{watcher} failed: #{error.class}: #{error.message}")
    end
  end
end
