# frozen_string_literal: true

module Integrations
  module Twitch
    ChannelUpdate = Data.define(:title, :category_id, :category_name, :language) do
      def self.from_event(event)
        new(
          title: event.fetch("title"),
          category_id: event.fetch("category_id").presence,
          category_name: event.fetch("category_name").presence,
          language: event.fetch("language")
        )
      end
    end
  end
end
