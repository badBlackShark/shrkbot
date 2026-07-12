# frozen_string_literal: true

module Moderation
  module Unpunisher
    module_function

    def call(server:, user_id:, punishment:)
      case punishment
      when "timeout"
        member = server.member(user_id)
        return :not_in_server unless member

        member.communication_disabled_until = nil
        :reversed
      when "ban"
        server.unban(user_id)
        :reversed
      else
        :noop
      end
    rescue => e
      Rails.logger.warn("[Moderation::Unpunisher] #{punishment} reversal failed: #{e.class}: #{e.message}")
      :failed
    end
  end
end
