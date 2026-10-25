# frozen_string_literal: true

module Integrations
  module Steam
    class News
      def initialize(client: Client.new)
        @client = client
      end

      def for_app(app_id, count: 20, maxlength: 0)
        @client.get_json(
          :api,
          "/ISteamNews/GetNewsForApp/v2/",
          params: {appid: app_id, count:, maxlength:},
          status_errors: {403 => NotFound}
        ) do |body|
          body.fetch("appnews").fetch("newsitems").map { |item| news_item(item) }
        end
      end

      private

      def news_item(item)
        NewsItem.new(
          gid: item.fetch("gid").to_s,
          title: item.fetch("title"),
          url: encode_url(item.fetch("url")),
          author: item.fetch("author").presence,
          contents: item.fetch("contents"),
          feed_name: item.fetch("feedname"),
          feed_label: item.fetch("feedlabel"),
          feed_type: item.fetch("feed_type"),
          published_at: Time.zone.at(item.fetch("date")),
          tags: Array(item["tags"])
        )
      end

      def encode_url(url)
        url.gsub(/[^\x21-\x7E]/) { |char| char.bytes.map { |byte| format("%%%02X", byte) }.join }
      end
    end
  end
end
