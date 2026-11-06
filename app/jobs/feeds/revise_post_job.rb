# frozen_string_literal: true

module Feeds
  class RevisePostJob < ApplicationJob
    include ReportsExhaustion

    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(post, _event) { post.id }
    )
    self.log_arguments = false

    discard_on ActiveJob::DeserializationError

    def perform(post, event)
      Ops::Feeds::Posts::Revise.call(post:, event:)
    end
  end
end
