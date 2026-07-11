# frozen_string_literal: true

module Moderation
  module ScanProcessor
    module_function

    def call(context)
      bytes = ImageDownload.call(context.attachment_url)
      client = Ocr::Client.new
      hex = client.phash(bytes)
      state = PhashIndex.lookup(hex, context.server.id)

      Ops::Moderation::Phashes::MarkSeen.call(phash_hex: hex) unless state == :none
      return if state == :own_dismissed

      ocr_text = (state == :own_confirmed) ? "" : client.scan(bytes)["text"]
      verdict = Classifier.call(
        ocr_text:,
        hash_state: state,
        signals: context.signals,
        settings: context.settings
      )
      VerdictExecutor.call(verdict:, context:, phash: hex, hash_state: state, image_bytes: bytes)
    rescue Ocr::Error => e
      Rails.logger.warn("[Moderation::ScanProcessor] scan failed: #{e.class}: #{e.message}")
    end
  end
end
