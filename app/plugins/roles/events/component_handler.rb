# frozen_string_literal: true

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
      names = role_names(diff[:add] + diff[:remove])
      log_role_change(:role_gained, label(diff[:add] - had, names))
      log_role_change(:role_lost, label(diff[:remove] & had, names))
    end

    def log_role_change(name, roles)
      return if roles.empty?

      ActivityLog.record(server_configuration, :roles, name, bot: event.bot, actor: member.mention, roles:)
    end

    def member_set_role_ids
      member.roles.map(&:id) & set_role_ids
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
