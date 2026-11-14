# frozen_string_literal: true

module Feeds
  class Twitch
    module ProfileHeader
      private

      def header
        profile = event.watch.image_url
        return header_texts unless profile

        [Bot::Discord::Components.section(header_texts, accessory: Bot::Discord::Components.thumbnail(profile))]
      end

      def eyebrow
        Bot::Discord::Components.text("-# #{event.display_name} · #{Twitch.fetch_post_type(post_type).label}")
      end
    end
  end
end
