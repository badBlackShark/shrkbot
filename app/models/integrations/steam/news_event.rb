# frozen_string_literal: true

module Integrations
  module Steam
    class NewsEvent < Integrations::Event
      store_accessor :payload, :title, :url, :author, :feed_name, :feed_label, :body, :image_urls, :language

      validates :title, :url, :feed_name, presence: true

      def enrich
        self.language = Language.detect("#{title}\n#{body}")
      end
    end
  end
end
