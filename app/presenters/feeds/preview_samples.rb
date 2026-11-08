# frozen_string_literal: true

module Feeds
  class PreviewSamples
    def initialize(watch_name:, event_type:)
      @watch_name = watch_name
      @event_type = event_type
    end

    def tokens(names)
      names.index_with { |name| value(name) }
    end

    def value(name)
      return @watch_name if name.to_s == watch_token

      I18n.t("components.feeds.#{plugin_key}.samples.#{Feeds.event_key(@event_type)}.#{name}")
    end
  end
end
