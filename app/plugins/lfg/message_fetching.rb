# frozen_string_literal: true

module Lfg
  module MessageFetching
    private

    def fetch_message
      JSON.parse(Discordrb::API::Channel.message(Bot::Config.rest_token, event.channel.id, event.message.id))
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end

    def delete_message(message_id)
      Discordrb::API::Channel.delete_message(Bot::Config.rest_token, event.channel.id, message_id)
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end
  end
end
