# frozen_string_literal: true

module Bot
  class RoleUpsert < RoleEvent
    on :server_role_create, :server_role_update

    private

    def apply
      return unless event.role

      Ops::ServerConfiguration::ServerRole::Upsert.call(
        server_configuration:,
        role: GuildMetadata.role_data(event.role)
      )
    end
  end
end
