# frozen_string_literal: true

module Lfg
  module PingReply
    module_function

    def deliver(channel_id:, reply_to_id:, subject:, allowed_mentions:, container:)
      message_id = Bot::Discord::Components.create_message(channel_id:, content: subject, allowed_mentions:, reply_to_id:)
      Bot::Discord::Components.convert_to_v2(channel_id, message_id, container)
      message_id
    end
  end
end
