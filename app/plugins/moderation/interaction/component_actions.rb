# frozen_string_literal: true

module Moderation
  module Interaction
    module ComponentActions
      private

      def phash_hex
        CustomId.parse(event.custom_id)[:phash_hex]
      end

      def server_configuration
        @server_configuration ||= ServerConfiguration.find_by(discord_id: event.server&.id)
      end

      def member
        return @member if defined?(@member)

        @member = event.server&.member(event.user.id)
      end

      def authorized?
        StaffGate.allows?(member, server_configuration&.moderation_settings&.staff_role_id)
      end

      def reject
        event.respond(content: I18n.t("moderation.image_scanning.buttons.unauthorized"), ephemeral: true)
      end

      def resolve(text, verdict_decided:)
        blocks = retained_blocks
        blocks << Bot::Discord::Components.separator
        blocks << Bot::Discord::Components.text(text)
        blocks << action_row(verdict_decided:)
        container = Bot::Discord::Components.container(blocks)
        event.update_message(components: container[:components], has_components: true)
      end

      def action_row(verdict_decided:)
        buttons = verdict_buttons(verdict_decided:) + preserved_punishment_buttons
        Bot::Discord::Components.action_row(buttons)
      end

      def verdict_buttons(verdict_decided:)
        if verdict_decided
          [
            Bot::Discord::Components.button(
              custom_id: CustomId.undo_verdict(phash_hex),
              label: I18n.t("moderation.image_scanning.buttons.undo_verdict"),
              style: Bot::Discord::Components::BUTTON_SECONDARY
            )
          ]
        else
          [
            Bot::Discord::Components.button(
              custom_id: CustomId.confirm(phash_hex),
              label: I18n.t("moderation.image_scanning.buttons.confirm_button"),
              style: Bot::Discord::Components::BUTTON_SUCCESS
            ),
            Bot::Discord::Components.button(
              custom_id: CustomId.dismiss(phash_hex),
              label: I18n.t("moderation.image_scanning.buttons.dismiss_only_button"),
              style: Bot::Discord::Components::BUTTON_DANGER
            )
          ]
        end
      end

      def preserved_punishment_buttons
        existing = event.message.buttons.find do |button|
          button.custom_id&.start_with?("#{CustomId::PREFIX}:undo_punishment:")
        end
        return [] unless existing

        [
          Bot::Discord::Components.button(
            custom_id: existing.custom_id,
            label: existing.label,
            style: existing.style
          )
        ]
      end

      def retained_blocks
        root = event.message.components.first
        return [] unless root

        root.components.filter_map { |component| rebuild(component) }
      end

      def rebuild(component)
        if component.respond_to?(:content)
          Bot::Discord::Components.text(component.content)
        elsif component.respond_to?(:items)
          Bot::Discord::Components.media_gallery(component.items.map { |item| item.media.url })
        elsif component.respond_to?(:divider?)
          Bot::Discord::Components.separator
        end
      end
    end
  end
end
