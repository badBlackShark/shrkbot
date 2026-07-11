# frozen_string_literal: true

require "uri"

module Moderation
  module ImageScanning
    class VerdictExecutor
      def self.call(verdict:, context:, phash:, hash_state:, image_bytes: nil)
        new(verdict:, context:, phash:, hash_state:, image_bytes:).call
      end

      def initialize(verdict:, context:, phash:, hash_state:, image_bytes:)
        @verdict = verdict
        @context = context
        @phash = phash
        @hash_state = hash_state
        @image_bytes = image_bytes
      end

      def call
        case verdict.action
        when :flag_for_review
          flag(removed: false)
        when :remove
          delete_message if context.settings.action_delete?
          punish
          flag(removed: true)
        end
      end

      private

      attr_reader :verdict, :context, :phash, :hash_state, :image_bytes

      def delete_message
        context.bot.channel(context.channel_id)&.delete_message(context.message_id)
      rescue => e
        Rails.logger.warn("[Moderation::ImageScanning::VerdictExecutor] delete failed in ##{context.channel_id}: #{e.class}: #{e.message}")
      end

      def punish
        settings = context.settings
        escalate = hash_state == :own_confirmed && settings.confirmed_punishment != "none"
        punishment = escalate ? settings.confirmed_punishment : settings.punishment
        return if punishment == "none"

        Punisher.call(
          member: context.member,
          server: context.server,
          punishment:,
          timeout_seconds: escalate ? settings.confirmed_timeout_seconds : settings.timeout_seconds,
          reason: I18n.t("moderation.image_scanning.punishment.reason")
        )
      end

      def flag(removed:)
        config = context.settings.server_configuration
        settings = config.moderation_settings
        staff_role_id = settings.staff_role_id
        ping = settings.ping_staff
        state = removed ? "removed" : "flagged"
        image = image_bytes && Bot::Discord::FileUpload.new(image_bytes, File.basename(URI(context.attachment_url).path))

        Bot::ActivityLog.post(
          config,
          bot: context.bot,
          title: I18n.t("moderation.image_scanning.flag.title.#{state}"),
          body: StaffPing.prefix(staff_role_id, ping:) + I18n.t(
            "moderation.image_scanning.flag.body",
            author: "<@#{context.member.id}>",
            channel: "<##{context.channel_id}>",
            jump_url:
          ) + "\n" + risk_line(state) + "\n" + reason_lines,
          meta: I18n.t("moderation.image_scanning.flag.meta.#{state}"),
          image:,
          components: buttons,
          allowed_mentions: {parse: [], roles: StaffPing.allowed_roles(staff_role_id, ping:)}
        )
      end

      def buttons
        [
          Bot::Discord::Components.action_row(
            [
              Bot::Discord::Components.button(
                custom_id: Interaction::CustomId.confirm(phash),
                label: "Confirm scam",
                style: Bot::Discord::Components::BUTTON_SUCCESS
              ),
              Bot::Discord::Components.button(
                custom_id: Interaction::CustomId.dismiss(phash),
                label: "Dismiss",
                style: Bot::Discord::Components::BUTTON_DANGER
              )
            ]
          )
        ]
      end

      def jump_url
        "https://discord.com/channels/#{context.server.id}/#{context.channel_id}/#{context.message_id}"
      end

      def risk_line(state)
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

      def reason_lines
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
    end
  end
end
