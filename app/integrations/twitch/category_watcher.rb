# frozen_string_literal: true

module Integrations
  module Twitch
    class CategoryWatcher
      ID = /\A\d+\z/

      def self.resolve(input, games: Games.new)
        id = input.to_s.strip
        raise InvalidReference, "#{id.inspect} is not a Twitch category id" unless id.match?(ID)

        game = games.find(id)
        raise NotFound, "Twitch has no category #{id}" unless game

        target(game)
      end

      def self.refresh(external_ids, games: Games.new)
        games.for(external_ids).map { |game| target(game) }
      end

      def self.followed
        Watch.demanded.where(watcher: name)
      end

      def self.target(game)
        Target.new(
          external_id: game.id,
          name: game.name,
          image_url: game.box_art_url,
          url: "https://www.twitch.tv/directory/game/#{ERB::Util.url_encode(game.name)}"
        )
      end
      private_class_method :target
    end
  end
end
