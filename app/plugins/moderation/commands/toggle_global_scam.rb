# frozen_string_literal: true

module Moderation
  class ToggleGlobalScam < Bot::BaseCommand
    command_name "Toggle global scam block"
    command_type :message
    register_in :owner_guild
    plugin :image_scanning
    owner_only true

    def execute
      images = ImageScanning::ScannableImages.all(event.target)
      return event.respond(content: I18n.t("moderation.image_scanning.global_scam.none"), ephemeral: true) if images.empty?

      event.defer(ephemeral: true)
      marked, unmarked = toggle_all(images)
      event.edit_response(content: response_text(marked, unmarked))
    end

    private

    def response_text(marked, unmarked)
      return I18n.t("moderation.image_scanning.global_scam.failed") if marked.zero? && unmarked.zero?

      parts = []
      parts << I18n.t("moderation.image_scanning.global_scam.added", count: marked) if marked > 0
      parts << I18n.t("moderation.image_scanning.global_scam.removed", count: unmarked) if unmarked > 0
      parts.join(" ")
    end

    def toggle_all(images)
      marked = 0
      unmarked = 0
      images.each do |url|
        bytes = ImageScanning::ImageDownload.call(url)
        hex = ImageScanning::Ocr::Client.new.phash(bytes)
        now_global(hex) ? marked += 1 : unmarked += 1
      rescue ImageScanning::Ocr::Error => e
        Rails.logger.warn("[Moderation::ToggleGlobalScam] phash failed: #{e.class}: #{e.message}")
      end
      [marked, unmarked]
    end

    def now_global(hex)
      target = !::Moderation::Phash.find_by(phash: hex)&.global_scam
      Ops::Moderation::Phashes::SetGlobalScam.call(phash_hex: hex, global: target)
      target
    end
  end
end
