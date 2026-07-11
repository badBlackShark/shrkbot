# frozen_string_literal: true

module Welcomes
  class MemberLeave < Bot::BaseEvent
    on :member_leave

    def handle
      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.leave_message.blank?

      content = Message.render(setting.leave_message, user: "@#{event.user.username}", member_count: event.server.member_count)
      event.bot.send_message(setting.channel_id, content)
    end
  end
end
