# frozen_string_literal: true

require "net/http"

module Bot
  module Discord
    module Rest
      BASE = "https://discord.com/api/#{Config::API_VERSION}"
      TIMEOUT = 5

      module_function

      def get(path, authorization:)
        uri = URI("#{BASE}#{path}")
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri)
          request["Authorization"] = authorization
          http.request(request)
        end
      end
    end
  end
end
