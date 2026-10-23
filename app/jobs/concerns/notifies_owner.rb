# frozen_string_literal: true

module NotifiesOwner
  extend ActiveSupport::Concern

  ATTEMPTS = 10
  MAX_LISTED = 10

  included do
    retry_on StandardError, wait: :polynomially_longer, attempts: ATTEMPTS
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

  def owner_list(lines)
    listed = lines.first(MAX_LISTED).map { |line| "- #{line}" }
    listed << "- and #{lines.size - MAX_LISTED} more" if lines.size > MAX_LISTED
    listed
  end
end
