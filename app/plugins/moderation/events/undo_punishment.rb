# frozen_string_literal: true

module Moderation
  class UndoPunishment < Bot::BaseEvent
    include Interaction::ComponentActions

    on :button, custom_id: /\Amod:undo_punishment:/

    def handle
      return reject unless authorized?

      args = Interaction::CustomId.undo_punishment_args(event.custom_id)
      result = Unpunisher.call(server: event.server, user_id: args[:user_id], punishment: args[:punishment])
      apologize(args[:user_id]) if result == :reversed

      event.respond(content: feedback(result, args), ephemeral: true)
    end

    private

    def apologize(user_id)
      event.bot.user(user_id)&.pm(
        I18n.t("moderation.image_scanning.undo_punishment.apology", server: event.server.name)
      )
    rescue => e
      Rails.logger.warn("[Moderation::UndoPunishment] apology DM failed: #{e.class}: #{e.message}")
    end

    def feedback(result, args)
      case result
      when :reversed
        I18n.t("moderation.image_scanning.undo_punishment.reversed_#{args[:punishment]}", user: "<@#{args[:user_id]}>")
      when :not_in_server
        I18n.t("moderation.image_scanning.undo_punishment.not_in_server")
      else
        I18n.t("moderation.image_scanning.undo_punishment.failed")
      end
    end
  end
end
