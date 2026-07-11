# frozen_string_literal: true

require "net/http"
require "json"

module Moderation
  module ImageScanning
    module Ocr
      class Client
        def initialize
          @base = URI(ENV.fetch("OCR_URL"))
        end

        def phash(bytes)
          post("/phash", bytes).fetch("phash")
        end

        def scan(bytes)
          post("/scan", bytes)
        end

        private

        def post(path, bytes)
          uri = @base.dup
          uri.path = path
          response = Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https",
            open_timeout: 5,
            read_timeout: 60
          ) do |http|
            request = Net::HTTP::Post.new(uri)
            request.body = bytes
            request["Content-Type"] = "application/octet-stream"
            http.request(request)
          end
          unless response.code.to_i.between?(200, 299)
            raise Error, "OCR sidecar responded with #{response.code}"
          end

          JSON.parse(response.body)
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
          raise Error, e.message
        end
      end
    end
  end
end
