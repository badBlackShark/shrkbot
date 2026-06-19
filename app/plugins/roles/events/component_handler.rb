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

    def apply(diff, active)
      member.modify_roles(diff[:add], diff[:remove])
      notify(active)
    end

    def notify(active)
      return unless set.role_setting.notify_on_assign

      event.user.pm(Message.selection_summary(set, active))
    rescue
      nil
    end

    def update(picker)
      event.update_message(content: picker[:content], components: picker[:components])
    end
  end
end
