# frozen_string_literal: true

module Integrations
  module Steam
    class StoreItems
      def initialize(client: Client.new)
        @client = client
      end

      def hero_capsule_url(app_id)
        @client.get_json(:api, "/IStoreBrowseService/GetItems/v1/", params: {input_json: input(app_id).to_json}) do |body|
          assets = body.fetch("response").fetch("store_items").first&.dig("assets")
          next unless assets&.dig("hero_capsule")

          "#{Client::ASSET_HOST}/store_item_assets/#{assets.fetch("asset_url_format").sub("${FILENAME}", assets.fetch("hero_capsule"))}"
        end
      end

      private

      def input(app_id)
        {
          ids: [{appid: app_id.to_i}],
          context: {language: "english", country_code: "US"},
          data_request: {include_assets: true}
        }
      end
    end
  end
end
