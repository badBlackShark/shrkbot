# frozen_string_literal: true

module Welcomes
  class OnboardingComplete < Bot::BaseEvent
    on :member_update

    def handle
      member = event.user
      return if member.nil? || member.pending
      return unless PendingJoins.instance.forget(guild_id: event.server.id, user_id: member.id)

      JoinAnnouncement.new(bot: event.bot, server: event.server, member:).deliver
    end
  end
end
