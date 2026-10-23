# frozen_string_literal: true

module NotifiesOwner
  extend ActiveSupport::Concern

  included do
    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"
  end

  private

  def notify_owner(content)
    Bot::Discord::Components.create_message(
      channel_id: Bot::Discord::Components.dm_channel_id(Bot::Config.owner_id),
      content: Bot::Discord::Truncate.call(content, 2000),
      allowed_mentions: {parse: []}
    )
  end
end
