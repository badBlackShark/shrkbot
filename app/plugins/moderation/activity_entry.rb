# frozen_string_literal: true

module Moderation
  module ActivityEntry
    module_function

    def build(event_key, target:, moderator:, reason:, timeout_until: nil)
      {
        title: I18n.t("activity_log.moderation.title.#{event_key}", locale: :en, raise: true),
        body: body(event_key, target, moderator, reason, timeout_until),
        meta: I18n.t("activity_log.moderation.source", locale: :en, raise: true)
      }
    end

    def body(event_key, target, moderator, reason, timeout_until)
      [action_line(event_key, target, moderator, timeout_until), reason_line(reason)].join("\n")
    end

    def action_line(event_key, target, moderator, timeout_until)
      interpolations = {target: user_label(target), moderator: moderator_label(moderator), locale: :en, raise: true}
      interpolations[:until] = "<t:#{timeout_until.to_i}:f>" if timeout_until
      I18n.t("activity_log.moderation.#{event_key}", **interpolations)
    end

    def moderator_label(moderator)
      return I18n.t("activity_log.moderation.unknown_moderator", locale: :en, raise: true) unless moderator

      user_label(moderator)
    end

    def user_label(user)
      "#{user.mention} (#{user.username})"
    end

    def reason_line(reason)
      return I18n.t("activity_log.moderation.no_reason", locale: :en, raise: true) if reason.blank?

      I18n.t("activity_log.moderation.reason", reason:, locale: :en, raise: true)
    end

    private_class_method :body, :action_line, :moderator_label, :user_label, :reason_line
  end
end
