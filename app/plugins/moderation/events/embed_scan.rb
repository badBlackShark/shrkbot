# frozen_string_literal: true

module Moderation
  class EmbedScan < Bot::BaseEvent
    on :message_update

    def handle
      ImageScanning::EnqueueScan.call(
        event:,
        images: ImageScanning::ScannableImages.embeds(event.message)
      )
    end
  end
end
