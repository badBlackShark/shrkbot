# frozen_string_literal: true

module Moderation
  class ImageScan < Bot::BaseEvent
    on :message

    def handle
      ImageScanning::EnqueueScan.call(
        event:,
        images: ImageScanning::ScannableImages.on_create(event.message)
      )
    end
  end
end
