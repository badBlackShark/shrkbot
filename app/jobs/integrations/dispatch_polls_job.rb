# frozen_string_literal: true

module Integrations
  class DispatchPollsJob < ApplicationJob
    queue_as :default

    def perform(watcher)
      ActiveJob.perform_all_later(Watch.due.where(watcher:).map { |watch| PollJob.new(watch) })
    end
  end
end
