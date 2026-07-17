# frozen_string_literal: true

module VerifiesGuildChannels
  extend ActiveSupport::Concern

  private

  def guild_channels?(*channel_ids)
    ids = channel_ids.flatten.compact_blank.map(&:to_s).uniq
    ids.empty? || @server_configuration.server_channels.where(discord_id: ids).count == ids.size
  end
end
