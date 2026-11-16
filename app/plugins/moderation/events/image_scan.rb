# frozen_string_literal: true

module Moderation
  class ImageScan < Bot::BaseEvent
    on :message

    def handle
      message = event.message
      ImageScanning::EnqueueScan.call(
        event:,
        images: ImageScanning::ScannableImages.attachments(message) +
          ImageScanning::ScannableImages.content_links(message) +
          ImageScanning::ScannableImages.forwarded(message)
      )
    end
  end
end
