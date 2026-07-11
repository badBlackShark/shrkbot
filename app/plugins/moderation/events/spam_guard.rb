# frozen_string_literal: true

module Moderation
  class SpamGuard < Bot::BaseEvent
    on :message

    CONTENT_PREVIEW_LIMIT = 800

    def handle
      return if event.from_bot? || event.message.webhook? || event.channel.pm?

      settings = SpamProtection::Settings.active_for(event.server.id)
      return unless settings

      config = settings.server_configuration
      staff_role_id = config.moderation_settings.staff_role_id

      return if Exemption.exempt?(member: event.author, server: event.server, staff_role_id:)

      hit = detect(settings)
      return unless hit
      return sweep_followup(hit, settings, config) if hit.followup?

      purge(hit.entries) if settings.action_purge?
      punish(settings)
      notify(config, settings, staff_role_id, hit.entries)
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

    def purge(entries)
      entries.each do |entry|
        event.bot.channel(entry.channel_id)&.delete_message(entry.message_id)
      rescue => e
        Rails.logger.warn("[Moderation::SpamGuard] delete failed in ##{entry.channel_id}: #{e.class}: #{e.message}")
      end
    end

    def punish(settings)
      return if settings.punishment_none?

      Punisher.call(
        member: event.author,
        server: event.server,
        punishment: settings.punishment,
        timeout_seconds: settings.timeout_seconds,
        reason: I18n.t("moderation.spam_protection.punishment.reason")
      )
    end

    def notify(config, settings, staff_role_id, entries)
      ping = config.moderation_settings.ping_staff
      channels = entries.map(&:channel_id).uniq
      body = StaffPing.prefix(staff_role_id, ping:) + I18n.t(
        "moderation.spam_protection.notification.body",
        author: "<@#{event.author.id}>",
        count: channels.size,
        window: settings.window_seconds,
        channels: channels.map { |id| "<##{id}>" }.join(", ")
      )
      quoted = quoted_content
      body += "\n#{quoted}" if quoted

      Bot::ActivityLog.post(
        config,
        bot: event.bot,
        title: I18n.t("moderation.spam_protection.notification.title.#{settings.action}"),
        body:,
        meta: I18n.t("moderation.spam_protection.notification.meta.#{settings.action}"),
        allowed_mentions: {parse: [], roles: StaffPing.allowed_roles(staff_role_id, ping:)}
      )
    end

    def sweep_followup(hit, settings, config)
      return unless settings.action_purge?

      purge(hit.entries)
      entry = hit.entries.first

      Bot::ActivityLog.post(
        config,
        bot: event.bot,
        title: I18n.t("moderation.spam_protection.notification.followup.title"),
        body: I18n.t(
          "moderation.spam_protection.notification.followup.body",
          author: "<@#{event.author.id}>",
          channel: "<##{entry.channel_id}>"
        ),
        meta: I18n.t("moderation.spam_protection.notification.followup.meta")
      )
    end

    def quoted_content
      content = event.message.content.to_s.strip
      return nil if content.empty?

      quoted = content.truncate(CONTENT_PREVIEW_LIMIT).lines.map { |line| "> #{line}" }.join
      I18n.t("moderation.spam_protection.notification.content_line", content: quoted)
    end
  end
end
