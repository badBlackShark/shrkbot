# frozen_string_literal: true

class ChannelOptions
  def initialize(server_configuration)
    @config = server_configuration
  end

  def options
    @config.server_channels.text.in_discord_order.map do |channel|
      Components::TomSelect::Option.for(value: channel.discord_id, label: channel.name)
    end
  end
end
