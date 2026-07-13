# frozen_string_literal: true

module Moderation
  module PunishmentNote
    module_function

    def line(punishment, timeout_until: nil)
      case punishment
      when "timeout"
        I18n.t("moderation.punishment_note.timeout", until: "<t:#{timeout_until.to_i}:f>")
      when "kick"
        I18n.t("moderation.punishment_note.kick")
      when "ban"
        I18n.t("moderation.punishment_note.ban")
      else
        I18n.t("moderation.punishment_note.none")
      end
    end
  end
end
