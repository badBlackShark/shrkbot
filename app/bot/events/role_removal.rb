# frozen_string_literal: true

module Bot
  class RoleRemoval < RoleEvent
    on :server_role_delete

    private

    def apply(config)
      role = config.server_roles.find_by(discord_id: event.id)
      return unless role

      Ops::ServerConfiguration::ServerRoles::Destroy.call(server_role: role)
    end
  end
end
