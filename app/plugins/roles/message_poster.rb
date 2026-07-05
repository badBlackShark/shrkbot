# frozen_string_literal: true

module Roles
  class MessagePoster
    def self.post(bot, set)
      new(bot, set).post
    end

    def initialize(bot, set)
      @bot = bot
      @set = set
    end

    def post
      return if @set.channel_id.nil?

      channel = @bot.channel(@set.channel_id)
      return unless channel

      rendered = Message.public_message(@set)
      @set.message_id ? edit(channel, rendered) : create(channel, rendered)
    end

    private

    def create(channel, rendered)
      message = Discord::Components.send_to(channel, rendered)
      @set.update!(message_id: message.id)
    end

    def edit(channel, rendered)
      channel.load_message(@set.message_id)&.edit(nil, nil, rendered[:components], rendered[:flags])
    end
  end
end
