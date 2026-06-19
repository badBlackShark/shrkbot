module Roles
  class Manage < ComponentHandler
    on :button, custom_id: /\Aroles:manage:/

    def handle
      return unless set && member

      active = member.roles.map(&:id) & set_role_ids
      picker = (set.selection_mode == "single") ? Message.single_picker(set, active) : Message.multi_picker(set, active)
      event.respond(content: picker[:content], components: picker[:components], ephemeral: true)
    end
  end
end
