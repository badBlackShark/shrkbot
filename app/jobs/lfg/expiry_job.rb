# frozen_string_literal: true

module Lfg
  class ExpiryJob < ApplicationJob
    queue_as :default

    def perform(channel_id, message_id)
      record = Lfg::Message.find_by(message_id:)
      cleanup(channel_id, record) if record
      delete(channel_id, message_id)
    end

    private

    def cleanup(channel_id, record)
      record.follow_up_ids.each { |id| delete(channel_id, id) }
      Ops::Lfg::Message::Destroy.call(message: record)
    end

    def delete(channel_id, message_id)
      Discordrb::API::Channel.delete_message(Bot::Config.rest_token, channel_id, message_id)
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end
  end
end
