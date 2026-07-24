# frozen_string_literal: true

module Welcomes
  class JoinAnnouncement
    # Stripping the mention drops the user object from the payload, so clients that have not lazily
    # loaded the member render it as @unknown-user. Keep the mention real and silence the message.
    SUPPRESS_NOTIFICATIONS = 1 << 12

    def initialize(bot:, server:, member:)
      @bot = bot
      @server = server
      @member = member
    end

    def enabled?
      setting&.channel_id.present? && setting.join_message.present?
    end

    def deliver
      return unless enabled?

      @bot.send_message(setting.channel_id, content, false, nil, nil, allowed_mentions, nil, nil, flags)
    end

    private

    def setting
      @setting ||= Settings.active_for(@server.id)
    end

    def content
      Message.render(
        setting.join_message,
        user: @member.mention,
        username: @member.username,
        displayname: @member.display_name,
        member_count: @server.member_count
      )
    end

    def allowed_mentions
      {parse: [], users: [@member.id]} unless setting.ping_on_join
    end

    def flags
      setting.ping_on_join ? 0 : SUPPRESS_NOTIFICATIONS
    end
  end
end
