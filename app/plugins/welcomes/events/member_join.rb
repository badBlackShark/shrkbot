# frozen_string_literal: true

module Welcomes
  class MemberJoin < Bot::BaseEvent
    on :member_join

    def handle
      announcement = JoinAnnouncement.new(bot: event.bot, server: event.server, member: event.user)
      return unless announcement.enabled?

      if event.user.pending
        PendingJoins.instance.remember(guild_id: event.server.id, user_id: event.user.id)
      else
        announcement.deliver
      end
    end
  end
end
