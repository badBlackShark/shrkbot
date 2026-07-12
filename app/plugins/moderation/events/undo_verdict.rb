# frozen_string_literal: true

module Moderation
  class UndoVerdict < Bot::BaseEvent
    include Interaction::ComponentActions

    on :button, custom_id: /\Amod:undo_verdict:/

    def handle
      return reject unless authorized?

      Ops::Moderation::Phashes::Clear.call(server_configuration:, phash_hex:)
      resolve(I18n.t("moderation.image_scanning.buttons.verdict_undone", actor: member.mention))
    end
  end
end
