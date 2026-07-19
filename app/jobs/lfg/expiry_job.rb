# frozen_string_literal: true

module Lfg
  class ExpiryJob < ApplicationJob
    queue_as :default

    def perform(channel_id, message_id)
      json = fetch(channel_id, message_id)
      notify_id = json && Lfg::PostMessage.parse(json)&.dig(:notify_reply_id)
      delete(channel_id, notify_id) if notify_id
      delete(channel_id, message_id)
    end

    private

    def fetch(channel_id, message_id)
      JSON.parse(Discordrb::API::Channel.message(Bot::Config.rest_token, channel_id, message_id))
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end

    def delete(channel_id, message_id)
      Discordrb::API::Channel.delete_message(Bot::Config.rest_token, channel_id, message_id)
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end
  end
end
