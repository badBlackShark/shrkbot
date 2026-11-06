# frozen_string_literal: true

module Feeds
  module Twitch
    module ProfileHeader
      private

      def header
        profile = event.watch.image_url
        return header_texts unless profile

        [Bot::Discord::Components.section(header_texts, accessory: Bot::Discord::Components.thumbnail(profile))]
      end
    end
  end
end
