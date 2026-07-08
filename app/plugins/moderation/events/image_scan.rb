# frozen_string_literal: true

module Moderation
  class ImageScan < BaseEvent
    on :message

    IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
    MAX_ATTACHMENTS = 3
    MAX_BYTES = 10 * 1024 * 1024

    def handle
      return if event.from_bot? || event.message.webhook? || event.channel.pm?

      settings = ImageScanning::Settings.active_for(event.server.id)
      return unless settings

      attachments = eligible_attachments
      return if attachments.empty?

      signals = Signals.call(author: event.author, content: event.message.content, server_id: event.server.id)

      attachments.each do |attachment|
        context = context_for(attachment, settings, signals)
        ScanQueue.enqueue(-> { ScanProcessor.call(context) })
      end
    end

    private

    def eligible_attachments
      event.message.attachments
        .select { |attachment| IMAGE_CONTENT_TYPES.include?(attachment.content_type) && attachment.size <= MAX_BYTES }
        .first(MAX_ATTACHMENTS)
    end

    def context_for(attachment, settings, signals)
      ScanContext.new(
        bot: event.bot,
        server: event.server,
        member: event.author,
        channel_id: event.channel.id,
        message_id: event.message.id,
        attachment_url: attachment.url,
        signals:,
        settings:
      )
    end
  end
end
