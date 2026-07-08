# frozen_string_literal: true

module Moderation
  module Punisher
    module_function

    def call(member:, server:, punishment:, timeout_seconds:, reason:)
      case punishment
      when "timeout"
        member.communication_disabled_until = Time.now + timeout_seconds
      when "kick"
        server.kick(member, reason)
      when "ban"
        server.ban(member, message_seconds: 0, reason:)
      end
    rescue => e
      Rails.logger.warn("[Moderation::Punisher] #{punishment} failed: #{e.class}: #{e.message}")
    end
  end
end
