# frozen_string_literal: true

require "net/http"
require "json"

module Bot
  module Discord
    class MessageApi
      BASE_URL = "https://discord.com/api/#{Config::API_VERSION}"

      class Error < StandardError
        attr_reader :status

        def initialize(message, status: nil)
          super(message)
          @status = status
        end
      end

      def self.create(channel_id:, body:)
        request(Net::HTTP::Post, "/channels/#{channel_id}/messages", body:) do |response|
          JSON.parse(response.body)["id"]
        end
      end

      def self.edit(channel_id:, message_id:, body:)
        request(Net::HTTP::Patch, "/channels/#{channel_id}/messages/#{message_id}", body:)
        nil
      end

      def self.delete(channel_id:, message_id:)
        request(Net::HTTP::Delete, "/channels/#{channel_id}/messages/#{message_id}", allow_404: true)
        nil
      end

      private_class_method def self.request(http_method, path, body: nil, allow_404: false)
        uri = URI("#{BASE_URL}#{path}")

        response = Net::HTTP.start(uri.host, uri.port, open_timeout: 5, read_timeout: 5, use_ssl: true) do |http|
          net_request = http_method.new(uri)
          net_request["Authorization"] = Config.rest_token
          if body
            net_request["Content-Type"] = "application/json"
            net_request.body = body.to_json
          end
          http.request(net_request)
        end

        return nil if allow_404 && response.code.to_i == 404
        unless response.code.to_i.between?(200, 299)
          raise Error.new("Discord responded with #{response.code}: #{response.body}", status: response.code.to_i)
        end

        block_given? ? yield(response) : nil
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
        raise Error.new(e.message, status: nil)
      end
    end
  end
end
