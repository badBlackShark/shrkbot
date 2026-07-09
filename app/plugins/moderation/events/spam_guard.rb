# frozen_string_literal: true

module Moderation
  class SpamGuard < BaseEvent
    on :message

    def handle
      return if event.from_bot? || event.message.webhook? || event.channel.pm?

      settings = SpamProtection::Settings.active_for(event.server.id)
      return unless settings

      config = settings.server_configuration
      staff_role_id = config.moderation_settings.staff_role_id

      return if staff_member?(staff_role_id)

      hit = detect(settings)
      return unless hit

      purge(hit) if settings.action == "purge"
      punish(settings)
      notify(config, settings, staff_role_id, hit)
    end

    private

    def fingerprints(settings)
      result = []
      content = Canonicalizer.call(event.message.content, strip_digits: true)

      if content.present?
        result << SimHash.fingerprint(content)
      elsif settings.match_symbol_only_messages
        result << "blank"
      end

      event.message.attachments.each do |attachment|
        result << "a:#{attachment.filename}:#{attachment.size}"
      end

      result
    end

    def detect(settings)
      fingerprints(settings).each do |fingerprint|
        hit = SpamTracker.instance.record(
          guild_id: event.server.id,
          author_id: event.author.id,
          fingerprint:,
          message_id: event.message.id,
          channel_id: event.channel.id,
          at: Time.current,
          window: settings.window_seconds,
          threshold: settings.channel_threshold,
          similarity: settings.similarity
        )
        return hit if hit
      end
      nil
    end

    def staff_member?(staff_role_id)
      return false unless staff_role_id

      event.author.roles.any? { |role| role.id == staff_role_id }
    end

    def purge(hit)
      hit.each do |entry|
        event.bot.channel(entry.channel_id)&.delete_message(entry.message_id)
      rescue => e
        Rails.logger.warn("[Moderation::SpamGuard] delete failed in ##{entry.channel_id}: #{e.class}: #{e.message}")
      end
    end

    def punish(settings)
      return if settings.punishment == "none"

      Punisher.call(
        member: event.author,
        server: event.server,
        punishment: settings.punishment,
        timeout_seconds: settings.timeout_seconds,
        reason: I18n.t("moderation.spam_protection.punishment.reason")
      )
    end

    def notify(config, settings, staff_role_id, hit)
      channels = hit.map(&:channel_id).uniq

      ActivityLog.post(
        config,
        bot: event.bot,
        title: I18n.t("moderation.spam_protection.notification.title.#{settings.action}"),
        body: StaffPing.prefix(staff_role_id) + I18n.t(
          "moderation.spam_protection.notification.body",
          author: "<@#{event.author.id}>",
          count: channels.size,
          channels: channels.map { |id| "<##{id}>" }.join(", ")
        ),
        meta: I18n.t("moderation.spam_protection.notification.meta.#{settings.action}"),
        allowed_mentions: {parse: [], roles: [staff_role_id]}
      )
    end
  end
end
