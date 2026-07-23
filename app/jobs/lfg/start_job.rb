# frozen_string_literal: true

module Lfg
  class StartJob < ApplicationJob
    queue_as :default

    def perform(channel_id, message_id)
      json = fetch(channel_id, message_id)
      state = json && Lfg::PostMessage.parse(json)
      return if state.nil? || state[:joiner_ids].empty?

      ping_id = re_ping(channel_id, message_id, state[:joiner_ids])
      record = Lfg::Message.find_by(message_id:)
      Ops::Lfg::Message::Update.call(message: record, start_ping_id: ping_id) if record
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end

    private

    def fetch(channel_id, message_id)
      JSON.parse(Discordrb::API::Channel.message(Bot::Config.rest_token, channel_id, message_id))
    end

    def re_ping(channel_id, message_id, joiner_ids)
      mentions = Lfg::Mentions.list(joiner_ids)
      Lfg::PingReply.deliver(
        channel_id:,
        reply_to_id: message_id,
        subject: "The game you joined is starting now! #{mentions}",
        allowed_mentions: {parse: [], users: joiner_ids},
        container: Bot::Discord::Components.container(
          [Bot::Discord::Components.text("The game you joined is starting now! #{mentions}")]
        )
      )
    end
  end
end
