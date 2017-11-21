# Helper methods for abusing reactions :'(
module Reactions
  RATE_LIMIT = 0.25

  # Manually issues a reaction request
  def self.react(message, reaction)
    channel_id = message.channel.id
    message_id = message.id
    encoded_reaction = URI.encode(reaction)

    RestClient.put(
      "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/#{encoded_reaction}/@me",
      nil,
      Authorization: SHRK.token
    )
  end

  # Applies multiple reactions at the given `RATE_LIMIT`
  def self.spam_reactions(message, reactions)
    reactions.each do |r|
      react(message, r)
      sleep RATE_LIMIT
    end
  end

  # Shortcut method
  def self.confirm(message)
    react(message, Emojis.name_to_unicode('checkmark'))
  end

  # Shortcut method
  def self.error(message)
    react(message, Emojis.name_to_unicode('crossmark'))
  end
end
