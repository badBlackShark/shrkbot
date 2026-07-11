# frozen_string_literal: true

module Bot
  module ActivityLog
    SUPPRESS_MENTIONS = {parse: []}.freeze

    module_function

    def post(server_configuration, bot:, title:, body:, meta:, image: nil, components: [], allowed_mentions: SUPPRESS_MENTIONS)
      channel_id = server_configuration.logging_setting.channel_id
      return unless channel_id

      deliver(bot, channel_id, entry(title, body, meta, image:, components:), allowed_mentions:, attachments: image && [image])
    end

    def enabled?(server_configuration, action)
      return false unless server_configuration.plugins.enabled.exists?(key: :logging)

      server_configuration.logging_setting.action_enabled?(action)
    end

    def entry(title, body, meta, image: nil, components: [])
      blocks = [Discord::Components.text("**#{title}**\n#{body}\n-# #{meta}")]
      blocks << Discord::Components.media_gallery(["attachment://#{File.basename(image.path)}"]) if image
      blocks.concat(components)
      Discord::Components.container(blocks)
    end

    def deliver(bot, channel_id, entry, allowed_mentions: SUPPRESS_MENTIONS, attachments: nil)
      channel = bot.channel(channel_id)
      return unless channel

      Discord::Components.send_to(channel, entry, allowed_mentions:, attachments:)
    rescue => e
      Rails.logger.warn("[ActivityLog] could not write to ##{channel_id}: #{e.class}: #{e.message}")
    end

    private_class_method :entry, :deliver
  end
end
