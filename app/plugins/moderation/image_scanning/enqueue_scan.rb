# frozen_string_literal: true

module Moderation
  module ImageScanning
    class EnqueueScan
      def self.call(event:, images:)
        new(event, images).call
      end

      def initialize(event, images)
        @event = event
        @images = images
      end

      def call
        return if event.from_bot? || event.message.webhook? || event.channel.pm?
        return if images.empty?

        settings = Settings.active_for(event.server.id)
        return unless settings

        moderation_settings = settings.server_configuration.moderation_settings
        staff_role_id = moderation_settings.staff_role_id
        return if Exemption.exempt?(member: event.author, server: event.server, staff_role_id:)

        signals = Signals.call(author: event.author, content: event.message.content, server_id: event.server.id)

        images.each do |url|
          context = context_for(url, settings, signals, moderation_settings.new_account_age_days)
          ScanQueue.enqueue(-> { ScanProcessor.call(context) })
        end
      end

      private

      attr_reader :event, :images

      def context_for(url, settings, signals, new_account_age_days)
        ScanContext.new(
          bot: event.bot,
          server: event.server,
          member: event.author,
          channel_id: event.channel.id,
          message_id: event.message.id,
          image_url: url,
          signals:,
          new_account_age_days:,
          settings:
        )
      end
    end
  end
end
