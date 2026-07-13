# frozen_string_literal: true

require "uri"

module Moderation
  class ReportScam < Bot::BaseCommand
    command_name "Report as scam"
    command_type :message
    register_in :guild
    plugin :image_scanning
    requires_permissions :manage_messages

    def execute
      message = event.target
      attachments = ImageScanning::ImageAttachments.call(message)
      return event.respond(content: I18n.t("moderation.image_scanning.report.none"), ephemeral: true) if attachments.empty?

      event.defer(ephemeral: true)
      count, log_image = confirm_all(attachments, config)
      post_log(config, message, log_image) if count > 0
      event.edit_response(content: I18n.t("moderation.image_scanning.report.done", count:))
    end

    private

    def config
      @config ||= ServerConfiguration.find_by(discord_id: event.server.id)
    end

    def confirm_all(attachments, config)
      log_image = nil
      count = attachments.count do |attachment|
        bytes = ImageScanning::ImageDownload.call(attachment.url)
        hex = ImageScanning::Ocr::Client.new.phash(bytes)
        Ops::Moderation::Phashes::Confirm.call(server_configuration: config, phash_hex: hex)
        log_image ||= Bot::Discord::FileUpload.new(bytes, File.basename(URI(attachment.url).path))
        true
      rescue ImageScanning::Ocr::Error => e
        Rails.logger.warn("[Moderation::ReportScam] phash failed: #{e.class}: #{e.message}")
        false
      end
      [count, log_image]
    end

    def post_log(config, message, log_image)
      settings = config.image_scanning_settings
      deleted = settings.action_delete? && delete_message(message)
      meta_key = deleted ? "removed" : "kept"
      Bot::ActivityLog.post(
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
        image: log_image
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
