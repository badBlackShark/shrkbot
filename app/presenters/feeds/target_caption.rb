# frozen_string_literal: true

module Feeds
  class TargetCaption
    def self.call(plugin_key, external_id)
      key = "components.feeds.target_card.#{plugin_key}.external_id"
      I18n.t(key, id: external_id) if I18n.exists?(key)
    end
  end
end
