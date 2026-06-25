# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerRoles
      class Sync < ApplicationOperation
        receives :server_configuration, :roles, :bot_role_position

        def call
          roles.each do |data|
            role = server_configuration.server_roles.find_or_initialize_by(discord_id: data[:discord_id])
            role.update!(name: data[:name], position: data[:position], managed: data[:managed])
          end
          server_configuration.server_roles.where.not(discord_id: roles.map { |r| r[:discord_id] }).delete_all
          server_configuration.update!(bot_role_position: bot_role_position)
          ok(server_configuration.server_roles.reload)
        end
      end
    end
  end
end
