# frozen_string_literal: true

module Welcomes
  class MemberLeave < Bot::BaseEvent
    on :member_leave

    def handle
      PendingJoins.instance.forget(guild_id: event.server.id, user_id: event.user.id)

      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.leave_message.blank?

      message = content(setting.leave_message)
      return post(setting.channel_id, message) unless setting.suppress_removal_messages

      GracePeriod.after do
        post(setting.channel_id, message) unless removed_by_staff?
      end
    end

    private

    def post(channel_id, message)
      event.bot.send_message(channel_id, message, false, nil, nil, {parse: []})
    end

    def removed_by_staff?
      PendingRemovals.instance.forget(guild_id: event.server.id, user_id: event.user.id)
    end

    def content(template)
      Message.render(
        template,
        user: "@#{event.user.username}",
        username: event.user.username,
        displayname: event.user.display_name,
        member_count: event.server.member_count
      )
    end
  end
end
