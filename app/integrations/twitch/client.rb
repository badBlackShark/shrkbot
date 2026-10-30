# frozen_string_literal: true

module Integrations
  module Twitch
    class Client
      HOST = "https://api.twitch.tv/helix"
      MAX_IDS = 100

      def self.configured?
        ENV["TWITCH_CLIENT_ID"].present? && ENV["TWITCH_CLIENT_SECRET"].present?
      end

      def initialize(token: AppToken.new)
        @token = token
      end

      def get_json(path, params: {}, status_errors: {}, &)
        authorized do |headers|
          Http.get_json("#{HOST}#{path}", params:, headers:, status_errors:, &)
        end
      end

      def post_json(path, body:, status_errors: {}, &)
        authorized do |headers|
          Http.post_json("#{HOST}#{path}", body:, headers:, status_errors:, &)
        end
      end

      def delete(path, params: {}, status_errors: {})
        authorized do |headers|
          Http.delete("#{HOST}#{path}", params:, headers:, status_errors:)
        end
      end

      private

      def authorized
        current = headers
        begin
          yield current
        rescue Unauthorized
          @token.invalidate!
          yield headers
        end
      end

      def headers
        {"Client-Id" => ENV.fetch("TWITCH_CLIENT_ID"), "Authorization" => "Bearer #{@token.value}"}
      end
    end
  end
end
