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
          report.video_urls.present? ? config.template_with_video : config.template_without_video
        end

        def deliver
          posted? ? edit_posted : create_new(config.channel_id)
        end

        def posted?
          game.discord_channel_id.present? && game.discord_message_id.present?
        end

        def edit_posted
          edit_message(game.discord_channel_id, game.discord_message_id)
        rescue Discordrb::Errors::UnknownMessage
          create_new(config.channel_id)
        end

        def create_new(channel_id)
          return persist_location(channel_id, create_components(channel_id)) if message.mention_ids.empty?

          message_id = create_mention_subject(channel_id)
          persist_location(channel_id, message_id)
          edit_message(channel_id, message_id)
        end

        def create_components(channel_id)
          ::Bot::Discord::Components.create_components_message(
            channel_id:,
            rendered: message.rendered,
            allowed_mentions: {parse: []}
          )
        end

        def create_mention_subject(channel_id)
          ::Bot::Discord::Components.create_message(
            channel_id:,
            content: message.mention_ids.map { |id| "<@#{id}>" }.join(" "),
            allowed_mentions: {parse: [], users: message.mention_ids}
          )
        end

        def edit_message(channel_id, message_id)
          ::Bot::Discord::Components.edit_components(channel_id, message_id, message.rendered)
        end

        def persist_location(channel_id, message_id)
          game.update!(discord_channel_id: channel_id, discord_message_id: message_id)
        end
      end
    end
  end
end
