# frozen_string_literal: true

module Roles
  class Manage < ComponentHandler
    on :button, custom_id: /\Aroles:manage:/

    def handle
      return unless set && member

      active = member.roles.map(&:id) & set_role_ids
      picker = Message.multi_picker(set, active)
      event.respond(components: picker[:components], ephemeral: true, has_components: true)
    end
  end
end
