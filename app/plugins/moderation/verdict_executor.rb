# frozen_string_literal: true

module Moderation
  module VerdictExecutor
    module_function

    def call(verdict:, context:, phash:)
      case verdict.action
      when :flag_for_review
        flag(verdict, context, phash, removed: false)
      when :remove
        delete_message(context) if context.settings.action == "delete"
        punish(context)
        flag(verdict, context, phash, removed: true)
      end
    end

    def delete_message(context)
      context.bot.channel(context.channel_id)&.delete_message(context.message_id)
    rescue => e
      Rails.logger.warn("[Moderation::VerdictExecutor] delete failed in ##{context.channel_id}: #{e.class}: #{e.message}")
    end

    def punish(context)
      return if context.settings.punishment == "none"

      Punisher.call(
        member: context.member,
        server: context.server,
        punishment: context.settings.punishment,
        timeout_seconds: context.settings.timeout_seconds,
        reason: I18n.t("moderation.image_scanning.punishment.reason")
      )
    end

    def flag(verdict, context, phash, removed:)
      config = context.settings.server_configuration
      staff_role_id = config.moderation_settings.staff_role_id
      state = removed ? "removed" : "flagged"

      ActivityLog.post(
        config,
        bot: context.bot,
        title: I18n.t("moderation.image_scanning.flag.title.#{state}"),
        body: StaffPing.prefix(staff_role_id) + I18n.t(
          "moderation.image_scanning.flag.body",
          author: "<@#{context.member.id}>",
          channel: "<##{context.channel_id}>",
          jump_url: jump_url(context),
          risk: verdict.risk.round(1),
          reasons: format_reasons(verdict.reasons)
        ),
        meta: I18n.t("moderation.image_scanning.flag.meta.#{state}"),
        image_url: context.attachment_url,
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

    def format_reasons(reasons)
      reasons.map { |reason| reason.to_s.tr("_", " ") }.join(", ")
    end

    private_class_method :delete_message, :punish, :flag, :buttons, :jump_url, :format_reasons
  end
end
