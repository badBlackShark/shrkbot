# frozen_string_literal: true

module Welcomes
  class JoinAnnouncement
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

      @bot.send_message(setting.channel_id, content, false, nil, nil, mention_suppression)
    end

    private

    def setting
      @setting ||= Settings.active_for(@server.id)
    end

    def content
      Message.render(setting.join_message, user: @member.mention, member_count: @server.member_count)
    end

    def mention_suppression
      {parse: []} unless setting.ping_on_join
    end
  end
end
