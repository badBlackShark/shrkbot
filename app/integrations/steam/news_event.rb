# frozen_string_literal: true

module Integrations
  module Steam
    class NewsEvent < Integrations::Event
      store_accessor :payload, :title, :url, :author, :feed_name, :feed_label, :body, :image_urls, :story_key

      validates :title, :url, :feed_name, :story_key, presence: true
    end
  end
end
