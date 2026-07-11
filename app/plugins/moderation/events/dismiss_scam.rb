# frozen_string_literal: true

module Moderation
  class DismissScam < Bot::BaseEvent
    include Interaction::ComponentActions

    on :button, custom_id: /\Amod:dismiss:/

    def handle
      return reject unless authorized?

      row = Bot::Discord::Components.action_row(
        [
          Bot::Discord::Components.button(
            custom_id: Interaction::CustomId.dismiss_confirm(phash_hex),
            label: I18n.t("moderation.image_scanning.buttons.dismiss_button"),
            style: Bot::Discord::Components::BUTTON_DANGER
          )
        ]
      )
      container = Bot::Discord::Components.container([Bot::Discord::Components.text(I18n.t("moderation.image_scanning.buttons.dismiss_prompt")), row])
      event.respond(components: container[:components], ephemeral: true, has_components: true)
    end
  end
end
