# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerRole
      class Upsert < ApplicationOperation
        receives :server_configuration, :role

        def call
          record = server_configuration.server_roles.find_or_initialize_by(discord_id: role[:discord_id])
          record.update!(**Attributes.call(role))
          ok(record)
        end
      end
    end
  end
end
