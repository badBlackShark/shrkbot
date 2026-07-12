# frozen_string_literal: true

module Moderation
  class ConfirmScam < Bot::BaseEvent
    include Interaction::ComponentActions

    on :button, custom_id: /\Amod:confirm:/

    def handle
      return reject unless authorized?

      Ops::Moderation::Phashes::Confirm.call(server_configuration:, phash_hex:)
      resolve(I18n.t("moderation.image_scanning.buttons.confirmed", actor: member.mention), verdict_decided: true)
    end
  end
end
