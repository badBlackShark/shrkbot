# frozen_string_literal: true

module Lfg
  module Denial
    module_function

    def reason_text(reason, detail = nil)
      I18n.t("activity_log.lfg.reasons.#{reason}", **interpolations(reason, detail), locale: :en, raise: true)
    end

    def entry(reason:, detail:, actor_id:, role_id:, channel_name:)
      {
        title: I18n.t("activity_log.lfg.title", locale: :en, raise: true),
        body: I18n.t("activity_log.lfg.denied", actor: "<@#{actor_id}>", role: "<@&#{role_id}>", reason: reason_text(reason, detail), locale: :en, raise: true),
        meta: I18n.t("activity_log.lfg.source", channel: channel_name, locale: :en, raise: true)
      }
    end

    def interpolations(reason, detail)
      case reason
      when :too_new then {days: detail}
      when :cooldown then {time: humanize_seconds(detail.to_i)}
      when :channel_not_allowed then {channels: channel_mentions(detail)}
      when :missing_required_role, :missing_game_role, :has_excluded_role then {roles: role_mentions(detail)}
      else {}
      end
    end

    def channel_mentions(ids)
      Array(ids).map { |id| "<##{id}>" }.join(" ")
    end

    def role_mentions(ids)
      Array(ids).map { |id| "<@&#{id}>" }.join(" ")
    end

    def humanize_seconds(total)
      minutes, seconds = total.divmod(60)
      minutes.zero? ? "#{seconds}s" : "#{minutes}m #{seconds}s"
    end

    private_class_method :interpolations, :channel_mentions, :role_mentions, :humanize_seconds
  end
end
