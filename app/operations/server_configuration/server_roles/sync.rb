# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerRoles
      class Sync < ApplicationOperation
        receives :server_configuration, :roles, :bot_role_position

        def call
          existing = server_configuration.server_roles.index_by(&:discord_id)
          roles.each do |data|
            role = existing[data[:discord_id]] || server_configuration.server_roles.build(discord_id: data[:discord_id])
            role.update!(name: data[:name], position: data[:position], managed: data[:managed], color: data[:color] || 0, permissions: data[:permissions] || 0)
          end
          server_configuration.server_roles.where.not(discord_id: roles.map { |r| r[:discord_id] }).delete_all
          server_configuration.update!(bot_role_position:)
          ok(server_configuration.server_roles.reload)
        end
      end
    end
  end
end
