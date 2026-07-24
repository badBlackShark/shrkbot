# frozen_string_literal: true

module Welcomes
  class MemberLeave < Bot::BaseEvent
    on :member_leave

    def handle
      PendingJoins.instance.forget(guild_id: event.server.id, user_id: event.user.id)

      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.leave_message.blank?

      event.bot.send_message(setting.channel_id, content(setting.leave_message), false, nil, nil, {parse: []})
    end

    private

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
