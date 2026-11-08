# frozen_string_literal: true

module Feeds
  module Twitch
    module CategorySearch
      MAX_QUERY = 100

      def self.call(query)
        term = query.strip.first(MAX_QUERY)
        return [] if term.empty?

        CachedFetch.call(["feeds/twitch/category_search/v1", term.downcase], missing: "Twitch category search") do
          Integrations::Twitch::Categories.new.search(term).map { |game| {"id" => game.id, "name" => game.name} }
        end
      end
    end
  end
end
