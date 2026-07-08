# frozen_string_literal: true

module Moderation
  class ReportScam < BaseCommand
    command_name "Report as scam"
    command_type :message
    register_in :guild
    requires_permissions :manage_messages

    def execute
      message = event.target
      attachments = image_attachments(message)
      return event.respond(content: I18n.t("moderation.image_scanning.report.none"), ephemeral: true) if attachments.empty?

      event.defer(ephemeral: true)
      count = confirm_all(attachments)
      event.edit_response(content: I18n.t("moderation.image_scanning.report.done", count:))
    end

    private

    def image_attachments(message)
      return [] unless message

      message.attachments.select { |attachment| ImageScanning::CONTENT_TYPES.include?(attachment.content_type) }
    end

    def confirm_all(attachments)
      config = ServerConfiguration.find_by(discord_id: event.server.id)
      attachments.count do |attachment|
        hex = Ocr::Client.new.phash(ImageDownload.call(attachment.url))
        Ops::Moderation::Phashes::Confirm.call(server_configuration: config, phash_hex: hex)
        true
      rescue Ocr::Error => e
        Rails.logger.warn("[Moderation::ReportScam] phash failed: #{e.class}: #{e.message}")
        false
      end
    end
  end
end
