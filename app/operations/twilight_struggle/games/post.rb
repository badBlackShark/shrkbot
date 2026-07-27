# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Post < ApplicationOperation
        self.transactional = false

        receives :game, :server_configuration, :report

        def call
          return skipped("no channel is configured for it or any tournament above it") if config.channel_id.blank?
          return skipped("the Twilight Struggle plugin is disabled") unless plugin_enabled?

          deliver
          ok(game)
        end

        private

        def skipped(reason)
          Rails.logger.info { "#{self.class} skipped game #{game.external_id} for #{server_configuration.name}: #{reason}." }
          ok(game)
        end

        def plugin_enabled?
          server_configuration.enabled_plugin_keys.include?(::TwilightStruggle::PLUGIN_KEY)
        end

        def config
          @config ||= ::TwilightStruggle::EffectiveConfig.new(game.tournament, server_configuration)
        end

        def message
          @message ||= ::TwilightStruggle::Message.new(
            report:,
            template:,
            tournament_name: game.tournament.name,
            ping_players: config.ping_players?
          )
        end

        def template
          return config.template_video if report.video_urls.present?

          report.tie? ? config.template_tie : config.template_win
        end

        def deliver
          posted ? edit_posted : create_new(config.channel_id)
        end

        def posted
          return @posted if defined?(@posted)

          @posted = game.posted_messages.find_by(server_configuration:)
        end

        def edit_posted
          ::Bot::Discord::Components.edit_content(posted.discord_channel_id, posted.discord_message_id, message.content)
        rescue Discordrb::Errors::UnknownMessage
          create_new(config.channel_id)
        end

        def create_new(channel_id)
          message_id = ::Bot::Discord::Components.create_message(
            channel_id:,
            content: message.content,
            allowed_mentions: {parse: []}
          )
          Rails.logger.info { "#{self.class} posted game #{game.external_id} to #{server_configuration.name} as message #{message_id} in channel #{channel_id}." }
          persist_location(channel_id, message_id)
        end

        def persist_location(channel_id, message_id)
          record = posted || game.posted_messages.build(server_configuration:)
          record.update!(discord_channel_id: channel_id, discord_message_id: message_id)
        end
      end
    end
  end
end
