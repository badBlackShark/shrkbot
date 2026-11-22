# frozen_string_literal: true

module Feeds
  class TwitchCategory
    class PreviewSamples < Feeds::Twitch::PreviewSamples
      def initialize(event_type:, **)
        super(watch_name: I18n.t("components.feeds.twitch_category.preview_samples.streamer"), event_type:)
      end

      private

      def sample(group, name)
        I18n.t("components.feeds.twitch.samples.#{group}.#{name}")
      end
    end
  end
end
