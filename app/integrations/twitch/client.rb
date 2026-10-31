# frozen_string_literal: true

module Integrations
  module Twitch
    class Client
      HOST = "https://api.twitch.tv/helix"
      MAX_IDS = 100
      STATUS_ERRORS = {403 => Error}.freeze

      def self.configured?
        ENV["TWITCH_CLIENT_ID"].present? && ENV["TWITCH_CLIENT_SECRET"].present?
      end

      def initialize(token: AppToken.new)
        @token = token
      end

      def get_json(path, params: {}, status_errors: {}, &)
        authorized do |headers|
          Http.get_json("#{HOST}#{path}", params:, headers:, status_errors: STATUS_ERRORS.merge(status_errors), &)
        end
      end

      def post_json(path, body:, status_errors: {}, &)
        authorized do |headers|
          Http.post_json("#{HOST}#{path}", body:, headers:, status_errors: STATUS_ERRORS.merge(status_errors), &)
        end
      end

      def delete(path, params: {}, status_errors: {})
        authorized do |headers|
          Http.delete("#{HOST}#{path}", params:, headers:, status_errors: STATUS_ERRORS.merge(status_errors))
        end
      end

      def get_all(path, params: {}, status_errors: {}, &map)
        results = []
        cursor = nil
        loop do
          page_params = cursor ? params.merge(after: cursor) : params
          found, cursor = get_json(path, params: page_params, status_errors:) do |body|
            [map.call(body), body.fetch("pagination")["cursor"]]
          end
          results.concat(found)
          break unless cursor
        end
        results
      end

      private

      def authorized(&)
        with_token(&)
      rescue RateLimited => e
        raise if e.retry_after

        raise RateLimited.new(e.message, retry_after: seconds_until_reset(e.headers), headers: e.headers)
      end

      def with_token
        current = headers
        begin
          yield current
        rescue Unauthorized
          @token.invalidate!
          yield headers
        end
      end

      def seconds_until_reset(response_headers)
        reset = Integer(response_headers.fetch("ratelimit-reset", []).first, 10, exception: false)
        [reset - Time.current.to_i, 0].max if reset
      end

      def headers
        {"Client-Id" => ENV.fetch("TWITCH_CLIENT_ID"), "Authorization" => "Bearer #{@token.value}"}
      end
    end
  end
end
