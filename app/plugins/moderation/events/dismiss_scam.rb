# frozen_string_literal: true

module Moderation
  class DismissScam < BaseEvent
    include ComponentActions

    on :button, custom_id: /\Amod:dismiss:/

    def handle
      return reject unless authorized?

      row = Discord::Components.action_row(
        [
          Discord::Components.button(
            custom_id: CustomId.dismiss_confirm(phash_hex),
            label: I18n.t("moderation.image_scanning.buttons.dismiss_button"),
            style: Discord::Components::BUTTON_DANGER
          )
        ]
      )
      container = Discord::Components.container([Discord::Components.text(I18n.t("moderation.image_scanning.buttons.dismiss_prompt")), row])
      event.respond(components: container[:components], ephemeral: true, has_components: true)
    end
  end
end
