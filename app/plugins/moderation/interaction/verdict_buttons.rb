# frozen_string_literal: true

module Moderation
  module Interaction
    module VerdictButtons
      module_function

      def build(server_configuration:, phash_hex:)
        return [undo_button(phash_hex)] if decided?(server_configuration:, phash_hex:)

        [confirm_button(phash_hex), dismiss_button(phash_hex)]
      end

      def decided?(server_configuration:, phash_hex:)
        phash = ::Moderation::Phash.find_by(phash: phash_hex)
        return false unless phash

        phash.phash_confirmations.exists?(server_configuration:)
      end

      def undo_button(phash_hex)
        Bot::Discord::Components.button(
          custom_id: CustomId.undo_verdict(phash_hex),
          label: I18n.t("moderation.image_scanning.buttons.undo_verdict"),
          style: Bot::Discord::Components::BUTTON_SECONDARY
        )
      end

      def confirm_button(phash_hex)
        Bot::Discord::Components.button(
          custom_id: CustomId.confirm(phash_hex),
          label: I18n.t("moderation.image_scanning.buttons.confirm_button"),
          style: Bot::Discord::Components::BUTTON_SUCCESS
        )
      end

      def dismiss_button(phash_hex)
        Bot::Discord::Components.button(
          custom_id: CustomId.dismiss(phash_hex),
          label: I18n.t("moderation.image_scanning.buttons.dismiss_only_button"),
          style: Bot::Discord::Components::BUTTON_DANGER
        )
      end
    end
  end
end
