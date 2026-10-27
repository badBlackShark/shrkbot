# frozen_string_literal: true

module Integrations
  module Steam
    class Client
      HOSTS = {
        api: "https://api.steampowered.com",
        store: "https://store.steampowered.com"
      }.freeze
      ASSET_HOST = "https://shared.akamai.steamstatic.com"

      def get_json(host, path, params: {}, status_errors: {}, &)
        Http.get_json("#{HOSTS.fetch(host)}#{path}", params:, status_errors:, &)
      end
    end
  end
end
