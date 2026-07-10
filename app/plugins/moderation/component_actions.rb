# frozen_string_literal: true

module Moderation
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

    def resolve(text)
      blocks = retained_blocks
      blocks << Discord::Components.separator
      blocks << Discord::Components.text(text)
      container = Discord::Components.container(blocks)
      event.update_message(components: container[:components], has_components: true)
    end

    def retained_blocks
      root = event.message.components.first
      return [] unless root

      root.components.filter_map { |component| rebuild(component) }
    end

    def rebuild(component)
      if component.respond_to?(:content)
        Discord::Components.text(component.content)
      elsif component.respond_to?(:items)
        Discord::Components.media_gallery(component.items.map { |item| item.media.url })
      elsif component.respond_to?(:divider?)
        Discord::Components.separator
      end
    end
  end
end
