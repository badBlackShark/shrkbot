# frozen_string_literal: true

module Feeds
  module Twitch
    module CategorySearch
      MAX_QUERY = 100

      def self.call(query)
        term = query.strip.first(MAX_QUERY)
        return [] if term.empty?

        Rails.cache.fetch(["feeds/twitch/category_search/v1", term.downcase], expires_in: 1.day) do
          Integrations::Twitch::Categories.new.search(term).map { |game| {"id" => game.id, "name" => game.name} }
        end
      rescue Integrations::Error => error
        Rails.logger.warn("Feeds: no Twitch category search: #{error.class}: #{error.message}")
        nil
      end
    end
  end
end
