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

      def self.content_links(message)
        new(message).content_links
      end

      URL_PATTERN = %r{https?://\S+}
      TRAILING_PUNCTUATION = /[.,!?;:)\]>]+\z/

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

      def content_links
        message.content.to_s.scan(URL_PATTERN)
          .filter_map { |raw| discord_cdn_image_url(raw) }
          .first(MAX)
      end

      private

      attr_reader :message

      def discord_cdn_image_url(raw)
        url = raw.sub(TRAILING_PUNCTUATION, "")
        uri = URI.parse(url)
        return unless uri.is_a?(URI::HTTPS)
        return unless uri.port == 443
        return unless DISCORD_CDN_HOSTS.include?(uri.host)
        return unless IMAGE_EXTENSIONS.include?(File.extname(uri.path).downcase)

        url
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
