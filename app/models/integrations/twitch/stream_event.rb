# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamEvent < Integrations::Event
      store_accessor :payload, :session, :login, :display_name, :title, :category_id, :category_name, :started_at, :story_key, :viewer_count

      validates :session, :login, :display_name, :story_key, presence: true
    end
  end
end
