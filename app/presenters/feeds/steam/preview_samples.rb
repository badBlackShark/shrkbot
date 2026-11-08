# frozen_string_literal: true

module Feeds
  module Steam
    class PreviewSamples
      def initialize(watch_name:, event_type:)
        @watch_name = watch_name
        @event_type = event_type
      end

      def tokens(names)
        names.index_with { |name| value(name) }
      end

      def value(name)
        return @watch_name if name.to_s == "game"

        I18n.t("components.feeds.steam.samples.#{Feeds.event_key(@event_type)}.#{name}")
      end
    end
  end
end
