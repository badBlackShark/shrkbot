# frozen_string_literal: true

module Roles
  class ComponentHandler < Bot::BaseEvent
    private

    def set
      return unless event.server

      @set ||= server_configuration.role_setting.role_sets.find_by(id: CustomId.parse(event.custom_id)[:set_id])
    end

    def member
      return @member if defined?(@member)

      @member = event.server.member(event.user.id)
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
      gained = logged_roles(:role_gained, diff[:add] - had, names)
      lost = logged_roles(:role_lost, diff[:remove] & had, names)
      return if gained.empty? && lost.empty?

      Bot::ActivityLog.post(
        server_configuration,
        bot: event.bot,
        **ActivityEntry.build(set:, actor: member.mention, gained:, lost:)
      )
    end

    def logged_roles(name, role_ids, names)
      return [] unless Bot::ActivityLog.enabled?(server_configuration, "roles.#{name}")

      label(role_ids, names)
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
      @server_configuration ||= ServerConfiguration.find_by(discord_id: event.server.id)
    end
  end
end
