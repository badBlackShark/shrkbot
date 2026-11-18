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

    private

    def value(name)
      return @watch_name if name.to_s == watch_token

      sample(Feeds.event_key(@event_type), name)
    end

    def image_label(name)
      sample(:images, name)
    end

    def sample(group, name)
      I18n.t("components.feeds.#{self.class.module_parent.plugin_key}.samples.#{group}.#{name}")
    end
  end
end
