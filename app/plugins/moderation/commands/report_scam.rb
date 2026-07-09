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
      config = ServerConfiguration.find_by(discord_id: event.server.id)
      count, first_upload = confirm_all(attachments, config)
      post_log(config, message, first_upload) if count > 0
      event.edit_response(content: I18n.t("moderation.image_scanning.report.done", count:))
    end

    private

    def image_attachments(message)
      return [] unless message

      message.attachments.select { |attachment| ImageScanning::CONTENT_TYPES.include?(attachment.content_type) }
    end

    def confirm_all(attachments, config)
      first_upload = nil
      count = attachments.count do |attachment|
        bytes = ImageDownload.call(attachment.url)
        hex = Ocr::Client.new.phash(bytes)
        Ops::Moderation::Phashes::Confirm.call(server_configuration: config, phash_hex: hex)
        first_upload ||= Discord::FileUpload.new(bytes, File.basename(URI(attachment.url).path))
        true
      rescue Ocr::Error => e
        Rails.logger.warn("[Moderation::ReportScam] phash failed: #{e.class}: #{e.message}")
        false
      end
      [count, first_upload]
    end

    def post_log(config, message, first_upload)
      settings = config.image_scanning_settings
      deleted = settings.action == "delete" && delete_message(message)
      meta_key = deleted ? "removed" : "kept"
      ActivityLog.post(
        config,
        bot: event.bot,
        title: I18n.t("moderation.image_scanning.report.log.title"),
        body: I18n.t(
          "moderation.image_scanning.report.log.body",
          reporter: "<@#{event.user.id}>",
          author: "<@#{message.author.id}>",
          channel: "<##{event.channel.id}>"
        ),
        meta: I18n.t("moderation.image_scanning.report.log.meta.#{meta_key}"),
        image: first_upload
      )
    end

    def delete_message(message)
      message.delete
      true
    rescue => e
      Rails.logger.warn("[Moderation::ReportScam] delete failed: #{e.class}: #{e.message}")
      false
    end
  end
end
