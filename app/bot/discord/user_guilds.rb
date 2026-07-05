# frozen_string_literal: true

require "net/http"
require "json"

module Discord
  class UserGuilds
    API_VERSION = "v10"
    ENDPOINT = URI("https://discord.com/api/#{API_VERSION}/users/@me/guilds?with_counts=true")

    class Error < StandardError; end

    class Unauthorized < Error; end

    def self.call(access_token)
      new(access_token).call
    end

    def initialize(access_token)
      @access_token = access_token
    end

    def call
      response = request
      raise Unauthorized, "Discord rejected the access token" if response.code.to_i == 401
      unless response.code.to_i.between?(200, 299)
        raise Error, "Discord responded with #{response.code}"
      end

      JSON.parse(response.body).map { |guild| Guild.from_api(guild) }
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
      raise Error, e.message
    end

    private

    def request
      Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        get = Net::HTTP::Get.new(ENDPOINT)
        get["Authorization"] = "Bearer #{@access_token}"
        http.request(get)
      end
    end
  end
end
