# frozen_string_literal: true

module Feeds
  module Twitch
    module GameLookup
      def self.find(category_id)
        return unless category_id

        attributes = CachedFetch.call(["feeds/twitch/game/v1", category_id], missing: "Twitch category #{category_id}") do
          Integrations::Twitch::Games.new.find(category_id)&.to_h
        end
        Integrations::Twitch::Game.new(**attributes) if attributes
      end
    end
  end
end
