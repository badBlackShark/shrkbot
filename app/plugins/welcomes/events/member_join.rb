module Welcomes
  class MemberJoin < BaseEvent
    on :member_join

    def handle
      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.join_message.blank?

      content = Message.render(setting.join_message, user: event.user.mention, member_count: event.server.member_count)
      event.bot.send_message(setting.channel_id, content)
    end
  end
end
