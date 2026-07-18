# frozen_string_literal: true

require "net/http"
require "uri"

module Moderation
  module AttachmentDownload
    Error = Class.new(StandardError)

    MAX_BYTES = 10 * 1024 * 1024

    module_function

    def call(url, max_bytes: MAX_BYTES)
      uri = URI(url)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 30
      ) do |http|
        body = nil
        http.request_get(uri) do |response|
          unless response.code.to_i.between?(200, 299)
            raise Error, "download failed: #{response.code}"
          end
          raise Error, "attachment too large" if (response.content_length || 0) > max_bytes

          body = read_capped(response, max_bytes)
        end
        body
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      raise Error, e.message
    end

    def read_capped(response, max_bytes)
      body = +""
      response.read_body do |chunk|
        body << chunk
        raise Error, "attachment too large" if body.bytesize > max_bytes
      end
      body
    end
    private_class_method :read_capped
  end
end
