module Roles
  class ComponentHandler < BaseEvent
    private

    def set
      @set ||= Set.find_by(id: CustomId.parse(event.custom_id)[:set_id])
    end

    def member
      return @member if defined?(@member)

      @member = event.server&.member(event.user.id)
    end

    def set_role_ids
      set.assignable_roles.map(&:role_id)
    end

    def apply(diff)
      member.modify_roles(diff[:add], diff[:remove])
    end

    def update(picker)
      event.update_message(components: picker[:components], has_components: true)
    end
  end
end
