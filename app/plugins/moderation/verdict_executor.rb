# frozen_string_literal: true

require "uri"

module Moderation
  module VerdictExecutor
    module_function

    def call(verdict:, context:, phash:, image_bytes: nil)
      case verdict.action
      when :flag_for_review
        flag(verdict, context, phash, image_bytes:, removed: false)
      when :remove
        delete_message(context) if context.settings.action_delete?
        punish(context)
        flag(verdict, context, phash, image_bytes:, removed: true)
      end
    end

    def delete_message(context)
      context.bot.channel(context.channel_id)&.delete_message(context.message_id)
    rescue => e
      Rails.logger.warn("[Moderation::VerdictExecutor] delete failed in ##{context.channel_id}: #{e.class}: #{e.message}")
    end

    def punish(context)
      return if context.settings.punishment_none?

      Punisher.call(
        member: context.member,
        server: context.server,
        punishment: context.settings.punishment,
        timeout_seconds: context.settings.timeout_seconds,
        reason: I18n.t("moderation.image_scanning.punishment.reason")
      )
    end

    def flag(verdict, context, phash, image_bytes:, removed:)
      config = context.settings.server_configuration
      staff_role_id = config.moderation_settings.staff_role_id
      state = removed ? "removed" : "flagged"
      image = image_bytes && Discord::FileUpload.new(image_bytes, File.basename(URI(context.attachment_url).path))

      ActivityLog.post(
        config,
        bot: context.bot,
        title: I18n.t("moderation.image_scanning.flag.title.#{state}"),
        body: StaffPing.prefix(staff_role_id) + I18n.t(
          "moderation.image_scanning.flag.body",
          author: "<@#{context.member.id}>",
          channel: "<##{context.channel_id}>",
          jump_url: jump_url(context)
        ) + "\n" + risk_line(verdict, context, state) + "\n" + reason_lines(verdict),
        meta: I18n.t("moderation.image_scanning.flag.meta.#{state}"),
        image:,
        components: buttons(phash),
        allowed_mentions: {parse: [], roles: [staff_role_id].compact}
      )
    end

    def buttons(phash)
      [
        Discord::Components.action_row(
          [
            Discord::Components.button(
              custom_id: CustomId.confirm(phash),
              label: "Confirm scam",
              style: Discord::Components::BUTTON_SUCCESS
            ),
            Discord::Components.button(
              custom_id: CustomId.dismiss(phash),
              label: "Dismiss",
              style: Discord::Components::BUTTON_DANGER
            )
          ]
        )
      ]
    end

    def jump_url(context)
      "https://discord.com/channels/#{context.server.id}/#{context.channel_id}/#{context.message_id}"
    end

    def risk_line(verdict, context, state)
      threshold_key = (state == "removed") ? :remove : :flag
      threshold = Classifier::THRESHOLDS.fetch(context.settings.sensitivity)[threshold_key]
      I18n.t(
        "moderation.image_scanning.flag.risk_line.#{state}",
        risk: format_number(verdict.risk),
        threshold: format_number(threshold)
      )
    end

    def format_number(value)
      rounded = value.round(1)
      (rounded % 1).zero? ? rounded.to_i : rounded
    end

    def reason_lines(verdict)
      verdict.reasons.map { |reason| reason_line(reason) }.join("\n")
    end

    def reason_line(reason)
      text = "- #{reason_text(reason)}"
      return text unless reason.weight > 0

      text + " (`+#{format_number(reason.weight)}`)"
    end

    def reason_text(reason)
      case reason.key
      when :rule
        I18n.t("moderation.image_scanning.flag.reasons.rule", pattern: reason.detail)
      when :custom_keywords
        I18n.t("moderation.image_scanning.flag.reasons.custom_keywords", count: reason.detail)
      when :new_account
        I18n.t("moderation.image_scanning.flag.reasons.new_account", days: reason.detail)
      else
        I18n.t("moderation.image_scanning.flag.reasons.#{reason.key}")
      end
    end

    private_class_method :delete_message, :punish, :flag, :buttons, :jump_url,
      :risk_line, :format_number, :reason_lines, :reason_line, :reason_text
  end
end
