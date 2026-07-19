# frozen_string_literal: true

module Lfg
  class StartJob < ApplicationJob
    queue_as :default

    def perform(channel_id, message_id)
      json = fetch(channel_id, message_id)
      state = json && Lfg::PostMessage.parse(json)
      return if state.nil? || state[:joiner_ids].empty?

      re_ping(channel_id, message_id, state[:joiner_ids])
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end

    private

    def fetch(channel_id, message_id)
      JSON.parse(Discordrb::API::Channel.message(Bot::Config.rest_token, channel_id, message_id))
    end

    def re_ping(channel_id, message_id, joiner_ids)
      mentions = joiner_ids.map { |id| "<@#{id}>" }.join(" ")
      Lfg::PingReply.deliver(
        channel_id:,
        reply_to_id: message_id,
        subject: "It's game time! #{mentions}",
        allowed_mentions: {parse: [], users: joiner_ids},
        container: Bot::Discord::Components.container([Bot::Discord::Components.text("It's game time! #{mentions}")])
      )
    end
  end
end
