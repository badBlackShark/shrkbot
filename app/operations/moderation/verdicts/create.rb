# frozen_string_literal: true

module Ops
  module Moderation
    module Verdicts
      class Create < ApplicationOperation
        receives :server_configuration, :discord_user_id, :action, :punishment, :phash
        receives :log_channel_id, default: nil
        receives :log_message_id, default: nil

        def call
          record = ::Moderation::VerdictRecord.create!(
            server_configuration:,
            discord_user_id:,
            action:,
            punishment:,
            phash:,
            log_channel_id:,
            log_message_id:
          )
          ok(record)
        end
      end
    end
  end
end
