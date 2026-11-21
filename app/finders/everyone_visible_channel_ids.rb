# frozen_string_literal: true

module Finders
  class EveryoneVisibleChannelIds
    def self.for(server_configuration)
      new(server_configuration).ids
    end

    def initialize(server_configuration)
      @server_configuration = server_configuration
    end

    def ids
      @server_configuration.server_channels.text.where.not(hidden_from_everyone.arel.exists).pluck(:discord_id)
    end

    private

    def hidden_from_everyone
      ChannelOverwrite
        .where("channel_overwrites.server_channel_id = server_channels.id")
        .where(target_id: @server_configuration.discord_id)
        .where("channel_overwrites.deny & ? <> 0", ServerChannel::VIEW_CHANNEL)
    end
  end
end
