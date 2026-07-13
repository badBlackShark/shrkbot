# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ScanProcessor
      module_function

      def call(context)
        bytes = ImageDownload.call(context.image_url)
        client = Ocr::Client.new
        hex = client.phash(bytes)
        state = PhashIndex.lookup(hex, context.server.id)

        Ops::Moderation::Phashes::MarkSeen.call(phash_hex: hex) unless state == :none
        return if state == :own_dismissed

        ocr_text = CONFIRMED_HASH_STATES.include?(state) ? "" : client.scan(bytes)["text"]
        verdict = Classifier.call(
          ocr_text:,
          hash_state: state,
          signals: context.signals,
          settings: context.settings,
          new_account_age_days: context.new_account_age_days
        )
        VerdictExecutor.call(verdict:, context:, phash: hex, hash_state: state, image_bytes: bytes)
      rescue Ocr::Error => e
        Rails.logger.warn("[Moderation::ImageScanning::ScanProcessor] scan failed: #{e.class}: #{e.message}")
      end
    end
  end
end
