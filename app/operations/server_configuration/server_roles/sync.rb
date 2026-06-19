module Ops
  module ServerConfiguration
    module ServerRoles
      class Sync < ApplicationOperation
        receives :server_configuration, :roles

        def execute
          roles.each do |data|
            role = server_configuration.server_roles.find_or_initialize_by(discord_id: data[:discord_id])
            role.update!(name: data[:name])
          end
          server_configuration.server_roles.where.not(discord_id: roles.map { |r| r[:discord_id] }).delete_all
          ok(server_configuration.server_roles.reload)
        end
      end
    end
  end
end
