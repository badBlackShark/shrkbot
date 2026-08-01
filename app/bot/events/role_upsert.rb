# frozen_string_literal: true

module Bot
  class RoleUpsert < RoleEvent
    on :server_role_create, :server_role_update

    private

    def apply(config)
      return unless event.role

      Ops::ServerConfiguration::ServerRoles::Upsert.call(
        server_configuration: config,
        role: GuildMetadata.role_data(event.role)
      )
    end
  end
end
