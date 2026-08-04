# frozen_string_literal: true

module Welcomes
  class RemovalRecord < Bot::BaseEvent
    def handle
      target = event.entry.target
      return unless target

      PendingRemovals.instance.remember(guild_id: event.server.id, user_id: target.id)
    end
  end
end
