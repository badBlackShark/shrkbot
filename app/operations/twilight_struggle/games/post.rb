# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Post < ApplicationOperation
        self.transactional = false

        receives :game, :report

        def call
          return ok(game) if config.channel_id.blank?

          deliver
          ok(game)
        end

        private

        def config
          @config ||= ::TwilightStruggle::EffectiveConfig.new(game.tournament)
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
          posted? ? edit_posted : create_new(config.channel_id)
        end

        def posted?
          game.discord_channel_id.present? && game.discord_message_id.present?
        end

        def edit_posted
          ::Bot::Discord::Components.edit_content(game.discord_channel_id, game.discord_message_id, message.content)
        rescue Discordrb::Errors::UnknownMessage
          create_new(config.channel_id)
        end

        def create_new(channel_id)
          message_id = ::Bot::Discord::Components.create_message(
            channel_id:,
            content: message.content,
            allowed_mentions: {parse: [], users: message.mention_ids}
          )
          persist_location(channel_id, message_id)
        end

        def persist_location(channel_id, message_id)
          game.update!(discord_channel_id: channel_id, discord_message_id: message_id)
        end
      end
    end
  end
end
