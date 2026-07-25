# frozen_string_literal: true

module TwilightStruggle
  class DeleteMessageJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on "Discordrb::Errors::UnknownMessage"
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(channel_id, message_id)
      Bot::Discord::Components.delete_message(channel_id, message_id)
    end
  end
end
