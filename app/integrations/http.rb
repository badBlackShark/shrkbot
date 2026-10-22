# frozen_string_literal: true

require "net/http"
require "json"

module Integrations
  class Http
    USER_AGENT = "shrkbot (+https://shrkbot.com)"
    STATUS_ERRORS = {
      401 => Unauthorized,
      403 => Unauthorized,
      404 => NotFound,
      410 => NotFound
    }.freeze
    TRANSPORT_ERRORS = [
      Timeout::Error,
      SocketError,
      SystemCallError,
      IOError,
      OpenSSL::SSL::SSLError,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Zlib::Error,
      JSON::ParserError
    ].freeze

    def self.get_json(url, params: {}, status_errors: {}, &)
      new(url, params:, status_errors:).get_json(&)
    end

    def initialize(url, params:, status_errors:)
      @uri = URI(url)
      @uri.query = URI.encode_www_form(params).presence
      @status_errors = STATUS_ERRORS.merge(status_errors)
    end

    def get_json
      yield JSON.parse(response_body)
    rescue KeyError, TypeError, NoMethodError => e
      raise Unavailable, "#{@uri.host} changed its response: #{e.message}"
    rescue *TRANSPORT_ERRORS => e
      raise Unavailable, "#{@uri.host}: #{e.class}: #{e.message}"
    end

    private

    def response_body
      response = Net::HTTP.start(
        @uri.host,
        @uri.port,
        use_ssl: @uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 15,
        max_retries: 0
      ) do |http|
        http.request(request)
      end
      raise failure(response) unless response.code.to_i.between?(200, 299)

      response.body
    end

    def request
      Net::HTTP::Get.new(@uri).tap do |request|
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "application/json"
      end
    end

    def failure(response)
      status = response.code.to_i
      message = "#{@uri.host} responded #{status}"
      return rate_limited(response, message) if status == 429

      (@status_errors[status] || default_error(status)).new(message)
    end

    def rate_limited(response, message)
      RateLimited.new(message, retry_after: Integer(response["Retry-After"], 10, exception: false))
    end

    def default_error(status)
      (status >= 500) ? Unavailable : Error
    end
  end
end
