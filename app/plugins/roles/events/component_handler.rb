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

    def log_assignment(had, diff)
      gained = diff[:add] - had
      lost = diff[:remove] & had
      return if gained.empty? && lost.empty?

      names = role_names(gained + lost)
      event_name, options = assignment_event(label(gained, names), label(lost, names))
      ActivityLog.record(server_configuration, event_name, bot: event.bot, actor: member.mention, **options)
    end

    def member_set_role_ids
      member.roles.map(&:id) & set_role_ids
    end

    def assignment_event(gained, lost)
      if gained.any? && lost.any?
        [:roles_changed, {gained:, lost:}]
      elsif gained.any?
        [:role_gained, {roles: gained}]
      else
        [:role_lost, {roles: lost}]
      end
    end

    def label(role_ids, names)
      role_ids.map { |role_id| names[role_id] || "an unknown role" }
    end

    def role_names(role_ids)
      server_configuration.server_roles
        .where(discord_id: role_ids)
        .pluck(:discord_id, :name)
        .to_h
    end

    def server_configuration
      set.role_setting.server_configuration
    end
  end
end
