# frozen_string_literal: true

module Integrations
  module Twitch
    class ClipEvent < Integrations::Event
      store_accessor :payload, :clip_id, :display_name, :title, :url, :thumbnail_url, :duration, :creator_name, :category_id

      validates :clip_id, :display_name, :title, :url, presence: true
    end
  end
end
