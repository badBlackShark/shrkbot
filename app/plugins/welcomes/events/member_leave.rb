module Welcomes
  class MemberLeave < BaseEvent
    on :member_leave

    def handle
      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.leave_message.blank?

      # Discriminators are gone (2023 username migration), so a departed member is
      # the @handle — a mention would be a dead link.
      content = Message.render(setting.leave_message, user: "@#{event.user.username}", member_count: event.server.member_count)
      event.bot.send_message(setting.channel_id, content)
    end
  end
end
