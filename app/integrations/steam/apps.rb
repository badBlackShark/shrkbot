# frozen_string_literal: true

module Integrations
  module Steam
    class Apps
      def initialize(client: Client.new)
        @client = client
      end

      def find(app_id)
        @client.get_json(
          :store,
          "/api/appdetails",
          params: {appids: app_id, filters: "basic"},
          status_errors: {403 => Unavailable}
        ) do |body|
          entry = body.fetch(app_id.to_s)
          raise NotFound, "Steam has no app #{app_id}" unless entry.fetch("success")

          app(entry.fetch("data"))
        end
      end

      private

      def app(data)
        App.new(
          id: data.fetch("steam_appid"),
          name: data.fetch("name"),
          type: data.fetch("type"),
          header_image_url: data["header_image"]
        )
      end
    end
  end
end
