# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ChannelOverwrite
      class Replace < ApplicationOperation
        receives :server_channel, :overwrites
        receives :created, default: false

        def call
          existing = created ? {} : server_channel.channel_overwrites.index_by(&:target_id)
          overwrites.each do |data|
            overwrite = existing[data[:target_id]] || server_channel.channel_overwrites.build(target_id: data[:target_id])
            overwrite.update!(target_type: data[:target_type], allow: data[:allow], deny: data[:deny])
          end
          prune(existing)
          ok(server_channel)
        end

        private

        def prune(existing)
          return if existing.empty?

          server_channel.channel_overwrites.where.not(target_id: overwrites.map { |o| o[:target_id] }).delete_all
        end
      end
    end
  end
end
