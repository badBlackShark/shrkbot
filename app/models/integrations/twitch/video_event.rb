# frozen_string_literal: true

module Integrations
  module Twitch
    class VideoEvent < Integrations::Event
      store_accessor :payload, :video_id, :display_name, :title, :url, :thumbnail_url, :duration

      validates :video_id, :display_name, :title, :url, presence: true
    end
  end
end
