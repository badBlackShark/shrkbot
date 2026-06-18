module Roles
  # Posts (or re-renders) a set's public message and remembers its id. Runs in
  # the bot process; the config-change trigger that calls it is the Phase 8
  # Redis path, so for now it's invoked on demand.
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
      message = channel.send_message(rendered[:content], false, nil, nil, nil, nil, rendered[:components])
      @set.update!(message_id: message.id)
    end

    def edit(channel, rendered)
      channel.load_message(@set.message_id)&.edit(rendered[:content], nil, rendered[:components])
    end
  end
end
