# frozen_string_literal: true

module Moderation
  module ImageScanning
    module Signals
      module_function

      DISCORD_EPOCH_MS = 1_420_070_400_000
      LINK_PATTERN = %r{https?://}i

      def call(author:, content:, server_id:)
        {
          account_age_days: account_age_days(author.id),
          has_link: LINK_PATTERN.match?(content.to_s),
          has_role: author.roles.any? { |role| role.id != server_id }
        }
      end

      def account_age_days(discord_id)
        created_ms = (discord_id >> 22) + DISCORD_EPOCH_MS
        ((Time.current.to_f * 1000) - created_ms) / 86_400_000.0
      end
      private_class_method :account_age_days
    end
  end
end
