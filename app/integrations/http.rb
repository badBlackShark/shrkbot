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
    MAX_BYTES = 5.megabytes

    def self.get_json(url, params: {}, headers: {}, status_errors: {}, &)
      new(Net::HTTP::Get.new(uri(url, params)), headers:, status_errors:).json(&)
    end

    def self.post_form(url, form:, status_errors: {}, &)
      request = Net::HTTP::Post.new(uri(url, {}))
      request.set_form_data(form)
      new(request, status_errors:).json(&)
    end

    def self.post_json(url, body:, headers: {}, status_errors: {}, &)
      request = Net::HTTP::Post.new(uri(url, {}))
      request["Content-Type"] = "application/json"
      request.body = body.to_json
      new(request, headers:, status_errors:).json(&)
    end

    def self.delete(url, params: {}, headers: {}, status_errors: {})
      new(Net::HTTP::Delete.new(uri(url, params)), headers:, status_errors:).perform
    end

    def self.get_bytes(url)
      new(Net::HTTP::Get.new(uri(url, {})), accept: "*/*").bytes
    end

    def self.uri(url, params)
      URI(url).tap do |uri|
        uri.query = URI.encode_www_form(params) if params.any?
      end
    end
    private_class_method :uri

    def initialize(request, headers: {}, status_errors: {}, accept: "application/json")
      @request = request
      @request["User-Agent"] = USER_AGENT
      @request["Accept"] = accept
      headers.each do |name, value|
        @request[name] = value
      end
      @uri = request.uri
      @status_errors = STATUS_ERRORS.merge(status_errors)
    end

    def bytes
      body = response_body
      raise Unavailable, "#{@uri.host} sent more than #{MAX_BYTES} bytes" if body.bytesize > MAX_BYTES

      body
    rescue *TRANSPORT_ERRORS => e
      raise Unavailable, "#{@uri.host}: #{e.class}: #{e.message}"
    end

    def json
      yield JSON.parse(response_body)
    rescue KeyError, TypeError, NoMethodError => e
      raise Unavailable, "#{@uri.host} changed its response: #{e.message}"
    rescue *TRANSPORT_ERRORS => e
      raise Unavailable, "#{@uri.host}: #{e.class}: #{e.message}"
    end

    def perform
      response_body
      nil
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
        http.request(@request)
      end
      raise failure(response) unless response.code.to_i.between?(200, 299)

      response.body
    end

    def failure(response)
      status = response.code.to_i
      message = "#{@uri.host} responded #{status}"
      return rate_limited(response, message) if status == 429

      (@status_errors[status] || default_error(status)).new(message)
    end

    def rate_limited(response, message)
      RateLimited.new(
        message,
        retry_after: Integer(response["Retry-After"], 10, exception: false),
        headers: response.to_hash
      )
    end

    def default_error(status)
      (status >= 500) ? Unavailable : Error
    end
  end
end
