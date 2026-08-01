# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerChannels
      class Upsert < ApplicationOperation
        receives :server_configuration, :channel

        def call
          record = server_configuration.server_channels.find_or_initialize_by(discord_id: channel[:discord_id])
          created = record.new_record?
          record.update!(**Attributes.call(channel))
          ChannelOverwrites::Replace.call(
            server_channel: record,
            overwrites: channel[:overwrites],
            created:
          )
          ok(record)
        end
      end
    end
  end
end
