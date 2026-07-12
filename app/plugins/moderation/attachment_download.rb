# frozen_string_literal: true

require "net/http"
require "uri"

module Moderation
  module AttachmentDownload
    Error = Class.new(StandardError)

    module_function

    def call(url)
      uri = URI(url)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 30
      ) do |http|
        response = http.get(uri)
        unless response.code.to_i.between?(200, 299)
          raise Error, "download failed: #{response.code}"
        end

        response.body
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      raise Error, e.message
    end
  end
end
