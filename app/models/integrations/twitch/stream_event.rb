# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamEvent < Integrations::Event
      store_accessor :payload, :session, :login, :display_name, :title, :category_id, :category_name, :started_at, :viewer_count

      validates :session, :login, :display_name, presence: true

      def expired?
        watch.state["session"] != session
      end

      def published_at
        Time.iso8601(started_at)
      end
    end
  end
end
