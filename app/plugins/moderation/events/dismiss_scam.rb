# frozen_string_literal: true

module Moderation
  class DismissScam < Bot::BaseEvent
    include Interaction::ComponentActions

    on :button, custom_id: /\Amod:dismiss:/

    def handle
      return reject unless authorized?

      Ops::Moderation::Phashes::Dismiss.call(server_configuration:, phash_hex:)
      resolve(I18n.t("moderation.image_scanning.buttons.dismissed", actor: member.mention))
    end
  end
end
