# frozen_string_literal: true

module Moderation
  module MemberLog
    class ActivityEntry
      def self.build(event_key:, target:, moderator:, reason:, timeout_until: nil)
        new(event_key:, target:, moderator:, reason:, timeout_until:).build
      end

      def initialize(event_key:, target:, moderator:, reason:, timeout_until:)
        @event_key = event_key
        @target = target
        @moderator = moderator
        @reason = reason
        @timeout_until = timeout_until
      end

      def build
        {
          title: I18n.t("activity_log.moderation.title.#{event_key}", locale: :en, raise: true),
          body:,
          meta: I18n.t("activity_log.moderation.source", locale: :en, raise: true)
        }
      end

      private

      attr_reader :event_key, :target, :moderator, :reason, :timeout_until

      def body
        [action_line, reason_line].join("\n")
      end

      def action_line
        interpolations = {target: user_label(target), moderator: moderator_label, locale: :en, raise: true}
        interpolations[:until] = "<t:#{timeout_until.to_i}:f>" if timeout_until
        I18n.t("activity_log.moderation.#{event_key}", **interpolations)
      end

      def moderator_label
        return I18n.t("activity_log.moderation.unknown_moderator", locale: :en, raise: true) unless moderator

        user_label(moderator)
      end

      def user_label(user)
        "#{user.mention} (#{user.username})"
      end

      def reason_line
        return I18n.t("activity_log.moderation.no_reason", locale: :en, raise: true) if reason.blank?

        I18n.t("activity_log.moderation.reason", reason:, locale: :en, raise: true)
      end
    end
  end
end
