# frozen_string_literal: true

module Integrations
  module Steam
    class StoreItems
      ENDPOINT = "/IStoreBrowseService/GetItems/v1/"
      BATCH = 100

      def initialize(client: Client.new)
        @client = client
      end

      def hero_capsule_url(app_id)
        @client.get_json(:api, ENDPOINT, params: {input_json: input([app_id]).to_json}) do |body|
          assets = body.fetch("response").fetch("store_items").first&.dig("assets")
          asset_url(assets, assets["hero_capsule"]) if assets&.dig("hero_capsule")
        end
      end

      def find_all(app_ids)
        app_ids.each_slice(BATCH).flat_map do |slice|
          @client.get_json(:api, ENDPOINT, params: {input_json: input(slice).to_json}) do |body|
            body.fetch("response").fetch("store_items")
              .select { |item| item.fetch("success") == 1 }
              .map { |item| store_item(item) }
          end
        end
      end

      private

      def store_item(item)
        assets = item.fetch("assets")
        StoreItem.new(
          app_id: item.fetch("appid").to_s,
          name: item.fetch("name"),
          header_image_url: (asset_url(assets, assets["header"]) if assets["header"])
        )
      end

      def asset_url(assets, filename)
        "#{Client::ASSET_HOST}/store_item_assets/#{assets.fetch("asset_url_format").sub("${FILENAME}", filename)}"
      end

      def input(app_ids)
        {
          ids: app_ids.map { |app_id| {appid: app_id.to_i} },
          context: {language: "english", country_code: "US"},
          data_request: {include_assets: true}
        }
      end
    end
  end
end
