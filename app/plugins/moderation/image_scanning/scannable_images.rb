# frozen_string_literal: true

module Moderation
  module ImageScanning
    class ScannableImages
      URL_PATTERN = %r{https?://\S+}
      TRAILING_PUNCTUATION = /[.,!?;:)\]>]+\z/
      FILE_PATH = %r{\Ahttps?://[^/]+([^?#]*)}

      def self.all(message)
        return [] unless message

        new(message).all
      end

      def self.on_create(message)
        new(message).on_create
      end

      def self.on_update(message)
        new(message).on_update
      end

      def initialize(message)
        @message = message
      end

      def all
        distinct(own + forwarded)
      end

      def on_create
        distinct(attachments + content_links + forwarded)
      end

      def on_update
        distinct(embeds)
      end

      protected

      def own
        attachments + content_links + embeds
      end

      private

      attr_reader :message

      def attachments
        message.attachments
          .select { |a| CONTENT_TYPES.include?(a.content_type) && a.size <= AttachmentDownload::MAX_BYTES }
          .map(&:url)
      end

      def embeds
        message.embeds
          .filter_map(&:image)
          .select { |img| img.proxy_url && CONTENT_TYPES.include?(img.content_type) }
          .map(&:proxy_url)
      end

      def content_links
        message.content.to_s.scan(URL_PATTERN).filter_map { |raw| discord_cdn_image_url(raw) }
      end

      def forwarded
        message.snapshots.flat_map { |snapshot| self.class.new(snapshot).own }
      end

      def distinct(urls)
        urls.uniq { |url| CGI.unescape(url[FILE_PATH, 1] || url) }
      end

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
