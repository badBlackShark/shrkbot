# frozen_string_literal: true

module Lfg
  class ExpiryJob < ApplicationJob
    queue_as :default

    def perform(channel_id, message_id)
      Lfg::PostCleanup.close(Lfg::Message.find_by(message_id:), message_id) do |id|
        delete(channel_id, id)
      end
    end

    private

    def delete(channel_id, message_id)
      Discordrb::API::Channel.delete_message(Bot::Config.rest_token, channel_id, message_id)
    rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
      nil
    end
  end
end
