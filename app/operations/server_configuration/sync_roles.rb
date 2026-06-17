module Ops
  module ServerConfiguration
    class SyncRoles < ApplicationOperation
      def initialize(server_configuration:, roles:)
        @server_configuration = server_configuration
        @roles = roles
      end

      def call
        transaction do
          @roles.each do |data|
            role = @server_configuration.server_roles.find_or_initialize_by(discord_id: data[:discord_id])
            role.update!(name: data[:name])
          end
          @server_configuration.server_roles.where.not(discord_id: @roles.map { |r| r[:discord_id] }).delete_all
        end
        ok(@server_configuration.server_roles.reload)
      end
    end
  end
end
