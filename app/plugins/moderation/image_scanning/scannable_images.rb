# frozen_string_literal: true

module Moderation
  module ImageScanning
    class ScannableImages
      MAX = 3
      MAX_BYTES = 10 * 1024 * 1024

      def self.attachments(message)
        new(message).attachments
      end

      def self.embeds(message)
        new(message).embeds
      end

      def initialize(message)
        @message = message
      end

      def attachments
        message.attachments
          .select { |a| CONTENT_TYPES.include?(a.content_type) && a.size <= MAX_BYTES }
          .first(MAX)
          .map(&:url)
      end

      def embeds
        message.embeds
          .filter_map(&:image)
          .select { |img| img.proxy_url && CONTENT_TYPES.include?(img.content_type) }
          .first(MAX)
          .map(&:proxy_url)
      end

      private

      attr_reader :message
    end
  end
end
