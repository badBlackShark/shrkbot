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
      return false unless member

      role_id = server_configuration&.moderation_settings&.staff_role_id
      return true if role_id && member.roles.any? { |role| role.id == role_id }

      member.permission?(:manage_messages)
    end

    def reject
      event.respond(content: I18n.t("moderation.image_scanning.buttons.unauthorized"), ephemeral: true)
    end

    def resolve(text)
      container = Discord::Components.container([Discord::Components.text(text)])
      event.update_message(components: container[:components], has_components: true)
    end
  end
end
